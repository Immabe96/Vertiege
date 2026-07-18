import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import '../models/post.dart';
import '../models/resident.dart';
import '../models/sync_status.dart';
import '../models/world.dart';
import '../services/moderation_filter.dart';
import '../services/permission_service.dart';
import '../services/supabase.dart';
import '../services/analytics_events.dart';
import '../services/analytics_service.dart';
import '../services/crash_reporter.dart';
import 'world_provider.dart';
import '../services/storage_service.dart';
import '../services/media_service.dart';
import '../services/post_service.dart';
import '../services/world_service.dart';
import '../services/world_activity_service.dart';
import '../repositories/post_repository.dart';
import '../utils/id_generator.dart';
import '../utils/text_parser.dart';
import '../utils/haptics.dart';
import '../utils/nexus_feed_sort.dart';
import '../utils/provider_errors.dart';
import '../utils/rate_limiter.dart';
import '../widgets/nexus/feed_sort_dropdown.dart';
import '../config/achievements.dart';
import 'resident_provider.dart';
import 'notification_provider.dart';
import 'quest_provider.dart';
import 'achievement_provider.dart';
import 'post/post_mapper.dart';
import 'post/post_reaction_logic.dart';

part 'post_provider.g.dart';

class PostState {
  final List<Post> posts;
  final List<Post> followingPosts;
  final Set<String> bookmarkedPostIds;
  final String? error;
  final bool isLoading;
  final bool isPosting;
  final List<Post> scheduledPosts;
  final String? lastError;
  final bool isLoadingMore;
  final bool hasMorePosts;
  /// Residents in any joined world (for Nexus mutual-world filter).
  final Set<String> mutualWorldResidentIds;

  const PostState({
    this.posts = const [],
    this.followingPosts = const [],
    this.mutualWorldResidentIds = const {},
    this.bookmarkedPostIds = const {},
    this.error,
    this.isLoading = false,
    this.isPosting = false,
    this.scheduledPosts = const [],
    this.lastError,
    this.isLoadingMore = false,
    this.hasMorePosts = true,
  });

  bool get hasError => error != null;

  PostState copyWith({
    List<Post>? posts,
    List<Post>? followingPosts,
    Set<String>? mutualWorldResidentIds,
    Set<String>? bookmarkedPostIds,
    String? error,
    bool? isLoading,
    bool clearError = false,
    bool? isPosting,
    List<Post>? scheduledPosts,
    String? lastError,
    bool clearLastError = false,
    bool? isLoadingMore,
    bool? hasMorePosts,
  }) => PostState(
    posts: posts ?? this.posts,
    followingPosts: followingPosts ?? this.followingPosts,
    mutualWorldResidentIds:
        mutualWorldResidentIds ?? this.mutualWorldResidentIds,
    bookmarkedPostIds: bookmarkedPostIds ?? this.bookmarkedPostIds,
    error: clearError ? null : error ?? this.error,
    isLoading: isLoading ?? this.isLoading,
    isPosting: isPosting ?? this.isPosting,
    scheduledPosts: scheduledPosts ?? this.scheduledPosts,
    lastError: clearLastError ? null : lastError ?? this.lastError,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    hasMorePosts: hasMorePosts ?? this.hasMorePosts,
  );
}

@Riverpod(name: 'postProvider', keepAlive: true)
class PostNotifier extends _$PostNotifier {
  final PostRepository _postsRepository = const PostRepository();
  RealtimeChannel? _realtimeChannel;
  RealtimeChannel? _nexusRealtimeChannel;
  String? _realtimeWorldId;
  Set<String> _nexusWorldIds = {};
  bool _realtimePaused = false;
  Timer? _schedulerTimer;
  final Map<String, Set<String>> _userReactions = {};
  int _lastPersistedCount = 0;
  int _currentLimit = 20;
  String? _lastCursor;
  String? _nexusCursor;
  bool _hasMore = true;
  bool _nexusHasMore = true;

  @override
  PostState build() {
    ref.onDispose(() {
      unawaited(_realtimeChannel?.unsubscribe());
      unawaited(_nexusRealtimeChannel?.unsubscribe());
      _schedulerTimer?.cancel();
    });

    listenSelf((prev, next) {
      final residentId = ref.read(residentProvider).resident?.id;
      if (residentId == null) return;
      final prevIds = (prev?.posts ?? const <Post>[]).map((p) => p.id).toSet();
      final added =
          next.posts.where((p) => !prevIds.contains(p.id)).toList(growable: false);
      // Ignore feed hydration (many posts at once), only react to a single new post.
      if (added.length != 1) return;
      final post = added.single;
      if (post.residentId != residentId) return;
      ref.read(residentProvider.notifier).addRep(post.worldId, 5);
      _checkPostMilestones(post.residentId);
      _triggerPrestigeUpdate(post.worldId);
    });

    _loadScheduledPosts();
    _startScheduler();
    Future.microtask(_hydrateFromCache);
    return const PostState();
  }

  Future<void> _hydrateFromCache() async {
    if (state.posts.isNotEmpty) return;
    try {
      final raw = await StorageService.getString(StorageService.postsKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      final posts = list
          .map((e) => postFromJson(e as Map<String, dynamic>))
          .toList();
      if (posts.isEmpty) return;
      state = state.copyWith(posts: posts, isLoading: false);
    } catch (_) {}
  }

  static const String _scheduledKey = '@scheduled_posts';

  Future<void> _loadScheduledPosts() async {
    try {
      final raw = await StorageService.getString(_scheduledKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      final posts = list
          .map((e) => postFromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(scheduledPosts: posts);
    } catch (_) {}
  }

  void _startScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _publishReadyPosts();
    });
  }

  Future<void> _publishReadyPosts() async {
    final now = DateTime.now();
    final ready = state.scheduledPosts
        .where((p) => p.scheduledFor != null && p.scheduledFor!.isBefore(now))
        .toList();
    if (ready.isEmpty) return;

    for (final post in ready) {
      if (now.difference(post.scheduledFor!) > const Duration(minutes: 5)) {
        state = state.copyWith(
          scheduledPosts: state.scheduledPosts
              .where((p) => p.id != post.id)
              .toList(),
        );
        _persistScheduled();
        continue;
      }
      try {
        final result = await _postsRepository.createPost(
          post.copyWith(syncStatus: SyncStatus.pending),
        );
        if (result.isFailure) throw result.error ?? StateError('Post failed');
        state = state.copyWith(
          posts: [
            post.copyWith(syncStatus: SyncStatus.synced),
            ...state.posts,
          ],
          scheduledPosts: state.scheduledPosts
              .where((p) => p.id != post.id)
              .toList(),
        );
        _persist();
        _persistScheduled();
      } catch (e, st) {
        debugPrint('Failed to publish scheduled post: $e');
        CrashReporter.instance.recordError(
          e,
          st,
          hint: 'scheduled_post_publish',
        );
        state = state.copyWith(
          scheduledPosts: state.scheduledPosts
              .map(
                (p) => p.id == post.id
                    ? p.copyWith(failedPublishes: p.failedPublishes + 1)
                    : p,
              )
              .toList(),
        );
        _persistScheduled();
      }
    }
  }

  Future<void> _persistScheduled() async {
    if (state.scheduledPosts.length == _lastPersistedCount) return;
    final json = jsonEncode(state.scheduledPosts.map(postToJson).toList());
    await StorageService.setString(_scheduledKey, json);
    _lastPersistedCount = state.scheduledPosts.length;
  }

  Future<void> addPost({
    required String worldId,
    required String residentId,
    required String residentName,
    required String residentAvatar,
    required String content,
    String? imageUri,
    List<String>? imageUris,
    int tierValue = 1,
    bool isAnnouncement = false,
    String? repostOf,
    Poll? poll,
    bool isDecree = false,
    DateTime? scheduledFor,
  }) async {
    if (!RateLimiter.canProceed('create_post_$residentId', windowMs: 5000, maxCalls: 3)) {
      return;
    }
    state = state.copyWith(isPosting: true);
    final resident = ref.read(residentProvider).resident;
    if (resident == null) {
      state = state.copyWith(isPosting: false);
      return;
    }
    final isNexusFeed = WorldService.localOnlyWorldIds.contains(worldId);
    var effectiveWorldId = worldId;
    if (isNexusFeed) {
      final joined = resident.joinedWorldIds
          .where(WorldService.isRemoteWorldId)
          .toList();
      if (joined.isEmpty) {
        state = state.copyWith(
          isPosting: false,
          error: 'Join a world before posting',
          lastError: 'No joined world for Nexus compose',
        );
        return;
      }
      effectiveWorldId = joined.first;
    } else if (!resident.joinedWorldIds.contains(worldId)) {
      state = state.copyWith(isPosting: false);
      return;
    }

    if (!WorldService.localOnlyWorldIds.contains(effectiveWorldId)) {
      final world = ref.read(worldProvider).worlds[effectiveWorldId];
      final constitution = world?.constitution ?? const WorldConstitution();
      if (!WorldPermissions.canPost(
        resident,
        effectiveWorldId,
        world?.sovereignId,
        constitution: constitution,
      )) {
        state = state.copyWith(isPosting: false);
        return;
      }
      if (WorldPermissions.isMuted(resident, effectiveWorldId)) {
        state = state.copyWith(isPosting: false);
        return;
      }
    }

    final mentions = TextParser.extractMentions(content);
    final hashtags = TextParser.extractHashtags(content);

    final moderationResult = await ModerationFilter.checkContentAsync(content);
    final postStatus = moderationResult != null
        ? 'pending_review'
        : 'published';

    final post = Post(
      id: generateId(),
      worldId: effectiveWorldId,
      residentId: residentId,
      residentName: residentName,
      authorDisplayTitle: resident.title,
      residentAvatar: residentAvatar,
      content: content,
      imageUri: imageUri,
      imageUris: imageUris,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      tierAtPosting: ResidentTier.fromValue(tierValue),
      isAnnouncement: isAnnouncement,
      repostOf: repostOf,
      mentions: mentions,
      hashtags: hashtags,
      poll: poll,
      isDecree: isDecree,
      status: postStatus,
      scheduledFor: scheduledFor,
    );

    if (scheduledFor != null && scheduledFor.isAfter(DateTime.now())) {
      String? cloudImageUrl = imageUri;
      if (imageUri != null && !imageUri.startsWith('http')) {
        cloudImageUrl = await MediaService.uploadPostImage(imageUri, residentId);
        if (cloudImageUrl == null) {
          state = state.copyWith(
            isPosting: false,
            lastError: 'Image upload failed',
          );
          return;
        }
      }
      final scheduledPost = post.copyWith(
        imageUri: cloudImageUrl,
        imageUris:
            imageUris ?? (cloudImageUrl == null ? null : [cloudImageUrl]),
      );
      if (isSupabaseConfigured()) {
        final result = await _postsRepository.createPost(scheduledPost);
        if (result.isSuccess && result.data != null) {
          state = state.copyWith(
            scheduledPosts: [...state.scheduledPosts, result.data!],
            isPosting: false,
            clearLastError: true,
          );
          _persistScheduled();
          Haptics.medium();
          return;
        }
        if (!result.queued) {
          state = state.copyWith(
            isPosting: false,
            lastError: result.error?.toString() ?? 'Could not schedule post',
          );
          return;
        }
      }
      state = state.copyWith(
        scheduledPosts: [...state.scheduledPosts, scheduledPost],
        isPosting: false,
      );
      _persistScheduled();
      Haptics.medium();
      return;
    }

    // Upload image to Supabase Storage if local file
    String? cloudImageUrl = imageUri;
    if (imageUri != null && !imageUri.startsWith('http')) {
      cloudImageUrl = await MediaService.uploadPostImage(imageUri, residentId);
      if (cloudImageUrl == null) {
        state = state.copyWith(
          isPosting: false,
          lastError: 'Image upload failed',
        );
        return;
      }
    }

    final optimisticPost = post.copyWith(
      syncStatus: SyncStatus.pending,
      localTempId: post.id,
    );
    state = state.copyWith(posts: [optimisticPost, ...state.posts]);
    _persist();

    final result = await _postsRepository.createPost(
      optimisticPost.copyWith(
        imageUri: cloudImageUrl,
        imageUris:
            imageUris ?? (cloudImageUrl == null ? null : [cloudImageUrl]),
      ),
    );

    if (result.isSuccess) {
      final syncedUris = cloudImageUrl == null
          ? null
          : (imageUris ?? [cloudImageUrl]);
      final serverPost = result.data;
      final confirmed = (serverPost ?? optimisticPost).copyWith(
        imageUri: cloudImageUrl ?? serverPost?.imageUri ?? optimisticPost.imageUri,
        imageUris: syncedUris ?? serverPost?.imageUris ?? optimisticPost.imageUris,
        syncStatus: SyncStatus.synced,
        clearSyncError: true,
        clearLocalTempId: true,
      );
      state = state.copyWith(
        posts: [
          confirmed,
          ...state.posts.where(
            (p) =>
                p.id != post.id &&
                p.localTempId != post.id &&
                p.id != confirmed.id,
          ),
        ],
        isPosting: false,
        clearLastError: true,
        clearError: true,
      );
      unawaited(
        AnalyticsService.logEvent(
          AnalyticsEvents.postCreated,
          parameters: {'world_id': effectiveWorldId},
        ),
      );
      ref.read(residentProvider.notifier).addRep(effectiveWorldId, 5);
      unawaited(WorldActivityService.touchWorld(effectiveWorldId));
      _checkPostMilestones(residentId);
      _triggerPrestigeUpdate(effectiveWorldId);
    } else if (result.queued) {
      state = state.copyWith(
        isPosting: false,
        lastError: 'Post queued for sync',
      );
    } else {
      state = state.copyWith(
        posts: state.posts.map((p) {
          if (p.id != post.id && p.localTempId != post.id) return p;
          return p.copyWith(
            syncStatus: SyncStatus.error,
            syncError: result.error?.toString() ?? 'Queued for sync',
          );
        }).toList(),
        error: 'Failed to post - tap to retry',
        lastError: 'Failed to create post: ${result.error}',
        isPosting: false,
      );
    }
    _persist();

    if (result.isSuccess) {
      ref.read(residentProvider.notifier).awardActivityXp('post', 5);
      ref.read(questProvider.notifier).onPostCreated();
      Haptics.medium();
    }
  }

  void _checkPostMilestones(String residentId) {
    final postCount = state.posts
        .where((p) => p.residentId == residentId)
        .length;
    final notifier = ref.read(achievementProvider.notifier);
    if (postCount >= 1) notifier.autoAwardAchievement(achievementPioneerPoster);
    if (postCount >= 10) notifier.autoAwardAchievement(achievementVoiceOfRealm);
    if (postCount >= 50) notifier.autoAwardAchievement(achievementChronicler);
    if (postCount >= 100) notifier.autoAwardAchievement(achievementNexusScribe);
  }

  void _triggerPrestigeUpdate(String worldId) {
    final worldNotifier = ref.read(worldProvider.notifier);
    final world = ref.read(worldProvider).worlds[worldId];
    if (world == null) return;
    worldNotifier.updateWorldPrestige(
      worldId: worldId,
      memberCount: world.memberCount,
      memberTiers: _gatherMemberTiers(worldId),
      recentPosts: state.posts,
    );
    worldNotifier.addActivityScore(worldId, 3);
  }

  Map<String, int> _gatherMemberTiers(String worldId) {
    final resident = ref.read(residentProvider).resident;
    if (resident != null && resident.joinedWorldIds.contains(worldId)) {
      return {resident.id: resident.tier.value};
    }
    return {};
  }

  /// Toggles a reaction (RPC is toggle on server). Handles vote exclusivity.
  Future<void> toggleReaction(
    String postId,
    String reactionKey,
    String residentId,
  ) async {
    if (!RateLimiter.canProceed('reaction_$postId')) return;
    final userSet = _userReactions.putIfAbsent(postId, () => {});
    final wasActive = userSet.contains(reactionKey);
    final snapshotPosts = List<Post>.from(state.posts);
    final snapshotUser = Set<String>.from(userSet);

    if (!wasActive) {
      for (final other in exclusiveVoteKeysToClear(userSet, reactionKey)) {
        _applyReactionDelta(postId, other, -1);
        userSet.remove(other);
      }
    }

    if (wasActive) {
      userSet.remove(reactionKey);
      _applyReactionDelta(postId, reactionKey, -1);
    } else {
      userSet.add(reactionKey);
      _applyReactionDelta(postId, reactionKey, 1);
    }

    _persist();

    final result = await _postsRepository.addReaction(
      postId: postId,
      emoji: reactionKey,
      residentId: residentId,
    );

    if (!result.isSuccess && !result.queued) {
      state = state.copyWith(posts: snapshotPosts);
      _userReactions[postId] = snapshotUser;
      if (snapshotUser.isEmpty) _userReactions.remove(postId);
      _persist();
      return;
    }

    // Keep optimistic UI when queued; only award XP after confirmed success.
    if (!wasActive && result.isSuccess) {
      ref.read(residentProvider.notifier).awardActivityXp('reaction', 1);
      ref.read(questProvider.notifier).onReacted();

      final reactedPost = state.posts.where((p) => p.id == postId).firstOrNull;
      if (reactedPost != null && reactedPost.residentId != residentId) {
        ref
            .read(residentProvider.notifier)
            .awardActivityXpForUser(
              reactedPost.residentId,
              'received_reaction',
              2,
            );
        ref.read(notificationProvider.notifier).addNotification(
              type: NotificationType.like,
              message: 'Someone reacted to your post',
              recipientId: reactedPost.residentId,
              postId: postId,
              worldId: reactedPost.worldId,
              showInLocalInbox: false,
            );
        final totalReactions = reactedPost.reactions.values.fold<int>(
          0,
          (sum, c) => sum + c,
        );
        ref.read(notificationProvider.notifier).reactionMilestone(
              postId: postId,
              worldId: reactedPost.worldId,
              count: totalReactions,
            );
      }
    }
  }

  void addReaction(String postId, String emoji, String residentId) {
    unawaited(toggleReaction(postId, emoji, residentId));
  }

  void _applyReactionDelta(String postId, String reactionKey, int delta) {
    state = state.copyWith(
      posts: applyPostReactionDelta(state.posts, postId, reactionKey, delta),
    );
  }

  Set<String> userReactionsForPost(String postId) =>
      Set<String>.from(_userReactions[postId] ?? const {});

  void editPostStatus(String postId, String newStatus) {
    final posts = state.posts.map((p) {
      if (p.id == postId) return p.copyWith(status: newStatus);
      return p;
    }).toList();
    state = state.copyWith(posts: posts);
    _persist();
  }

  void editPost(String postId, String newContent) {
    final snapshotPosts = List<Post>.from(state.posts);
    final posts = state.posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(content: newContent, isEdited: true);
      }
      return p;
    }).toList();
    state = state.copyWith(posts: posts);
    _persist();
    unawaited(_syncEditPost(postId, newContent, snapshotPosts));
  }

  Future<void> _syncEditPost(
    String postId,
    String newContent,
    List<Post> snapshotPosts,
  ) async {
    final result = await _postsRepository.editPost(
      postId: postId,
      content: newContent,
    );
    if (!result.isSuccess && !result.queued) {
      state = state.copyWith(
        posts: snapshotPosts,
        lastError: result.error?.toString() ?? 'Could not edit post',
      );
      _persist();
    }
  }

  void togglePin(String postId) {
    final snapshotPosts = List<Post>.from(state.posts);
    final current = state.posts.where((p) => p.id == postId).firstOrNull;
    final nextPinned = !(current?.isPinned ?? false);
    final posts = state.posts.map((p) {
      if (p.id == postId) return p.copyWith(isPinned: nextPinned);
      return p;
    }).toList();
    state = state.copyWith(posts: posts);
    _persist();
    unawaited(_syncTogglePin(postId, nextPinned, snapshotPosts));
  }

  Future<void> _syncTogglePin(
    String postId,
    bool isPinned,
    List<Post> snapshotPosts,
  ) async {
    final result = await _postsRepository.setPinned(
      postId: postId,
      isPinned: isPinned,
    );
    if (!result.isSuccess && !result.queued) {
      state = state.copyWith(
        posts: snapshotPosts,
        lastError: result.error?.toString() ?? 'Could not update pin',
      );
      _persist();
    }
  }

  void deletePost(String postId) {
    final snapshotPosts = List<Post>.from(state.posts);
    final snapshotBookmarks = Set<String>.from(state.bookmarkedPostIds);
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
      bookmarkedPostIds: state.bookmarkedPostIds
          .where((id) => id != postId)
          .toSet(),
    );
    _persist();
    _persistBookmarks();
    unawaited(_syncDeletePost(postId, snapshotPosts, snapshotBookmarks));
  }

  Future<void> _syncDeletePost(
    String postId,
    List<Post> snapshotPosts,
    Set<String> snapshotBookmarks,
  ) async {
    final result = await _postsRepository.deletePost(postId);
    if (!result.isSuccess && !result.queued) {
      state = state.copyWith(
        posts: snapshotPosts,
        bookmarkedPostIds: snapshotBookmarks,
        lastError: result.error?.toString() ?? 'Could not delete post',
      );
      _persist();
      _persistBookmarks();
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true, clearLastError: true);
  }

  void addComment(String postId, Comment comment) {
    final post = state.posts.where((p) => p.id == postId).firstOrNull;
    if (post == null) return;

    final posts = state.posts.map((p) {
      if (p.id != postId) return p;
      return p.copyWith(comments: [...p.comments, comment]);
    }).toList();

    state = state.copyWith(posts: posts);
    _persist();

    unawaited(_postsRepository.addComment(postId: postId, comment: comment));

    ref.read(questProvider.notifier).onCommentAdded();
    if (post.residentId != comment.residentId) {
      ref.read(notificationProvider.notifier).addNotification(
            type: NotificationType.comment,
            message: 'Someone commented on your post',
            recipientId: post.residentId,
            postId: postId,
            worldId: post.worldId,
            showInLocalInbox: false,
          );
    }
  }

  void voteOnPoll(String postId, String pollOptionId) {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final snapshotPosts = List<Post>.from(state.posts);
    final posts = state.posts.map((p) {
      if (p.id != postId || p.poll == null) return p;

      final poll = p.poll!;

      final alreadyVoted = poll.votedResidentIds.contains(resident.id);
      if (alreadyVoted && !poll.isMultiChoice) return p;
      if (alreadyVoted) {
        final updatedOptions = poll.options.map((o) {
          if (o.id == pollOptionId) {
            return o.copyWith(voteCount: (o.voteCount - 1).clamp(0, 999999));
          }
          return o;
        }).toList();
        final updatedVoted = poll.votedResidentIds
            .where((id) => id != resident.id)
            .toList();
        return p.copyWith(
          poll: poll.copyWith(
            options: updatedOptions,
            votedResidentIds: updatedVoted,
          ),
        );
      }

      if (!poll.isMultiChoice && poll.votedResidentIds.isNotEmpty) return p;

      final updatedOptions = poll.options.map((o) {
        if (o.id == pollOptionId) return o.copyWith(voteCount: o.voteCount + 1);
        return o;
      }).toList();
      final updatedVoted = [...poll.votedResidentIds, resident.id];
      return p.copyWith(
        poll: poll.copyWith(
          options: updatedOptions,
          votedResidentIds: updatedVoted,
        ),
      );
    }).toList();

    state = state.copyWith(posts: posts);
    _persist();
    final updatedPost = posts.where((p) => p.id == postId).firstOrNull;
    final updatedPoll = updatedPost?.poll;
    if (updatedPost != null && updatedPoll != null) {
      unawaited(
        _syncVoteOnPoll(
          updatedPost: updatedPost,
          updatedPoll: updatedPoll,
          residentId: resident.id,
          pollOptionId: pollOptionId,
          snapshotPosts: snapshotPosts,
        ),
      );
    }
  }

  Future<void> _syncVoteOnPoll({
    required Post updatedPost,
    required Poll updatedPoll,
    required String residentId,
    required String pollOptionId,
    required List<Post> snapshotPosts,
  }) async {
    final result = await _postsRepository.votePoll(
      post: updatedPost,
      poll: updatedPoll,
      residentId: residentId,
      optionId: pollOptionId,
    );
    if (!result.isSuccess && !result.queued) {
      state = state.copyWith(
        posts: snapshotPosts,
        lastError: result.error?.toString() ?? 'Could not record vote',
      );
      _persist();
    }
  }

  void toggleEventRsvp(String postId, String residentId) {
    final posts = state.posts.map((p) {
      if (p.id != postId) return p;
      final rsvps = List<String>.from(p.eventRsvpIds);
      if (rsvps.contains(residentId)) {
        rsvps.remove(residentId);
      } else {
        rsvps.add(residentId);
      }
      return p.copyWith(eventRsvpIds: rsvps);
    }).toList();
    state = state.copyWith(posts: posts);
    _persist();
  }

  static const String _bookmarksKey = '@bookmarked_posts';

  void toggleBookmark(String postId) {
    Haptics.light();
    if (state.bookmarkedPostIds.contains(postId)) {
      _unbookmark(postId);
    } else {
      _bookmark(postId);
    }
  }

  void awardPost(String postId, String awardType, String residentId) {
    final posts = state.posts.map((p) {
      if (p.id != postId) return p;
      final awardKey = '$awardType:$residentId';
      if (p.awards.any((a) => a.startsWith('$awardType:'))) return p;
      return p.copyWith(awards: [...p.awards, awardKey]);
    }).toList();
    state = state.copyWith(posts: posts);
    _persist();

    final awardedPost = state.posts.where((p) => p.id == postId).firstOrNull;
    if (awardedPost != null && awardedPost.residentId != residentId) {
      ref.read(notificationProvider.notifier).addNotification(
            type: NotificationType.like,
            message: 'Someone gave your post an award!',
            recipientId: awardedPost.residentId,
            postId: postId,
            worldId: awardedPost.worldId,
            showInLocalInbox: false,
          );
    }
  }

  void _bookmark(String postId) {
    final updated = {...state.bookmarkedPostIds, postId};
    state = state.copyWith(bookmarkedPostIds: updated);
    _persistBookmarks();
    _syncBookmarkToSupabase(postId, add: true);
  }

  void _unbookmark(String postId) {
    final updated = state.bookmarkedPostIds.where((id) => id != postId).toSet();
    state = state.copyWith(bookmarkedPostIds: updated);
    _persistBookmarks();
    _syncBookmarkToSupabase(postId, add: false);
  }

  bool isBookmarked(String postId) => state.bookmarkedPostIds.contains(postId);

  Future<void> _persistBookmarks() async {
    final json = jsonEncode(state.bookmarkedPostIds.toList());
    await StorageService.setString(_bookmarksKey, json);
  }

  Future<void> _syncBookmarkToSupabase(
    String postId, {
    required bool add,
  }) async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    await _postsRepository.setBookmark(
      postId: postId,
      residentId: resident.id,
      bookmarked: add,
    );
  }

  Future<void> loadBookmarks() async {
    final localIds = await _loadLocalBookmarks();

    final remoteIds = await _loadRemoteBookmarks();

    final merged = {...localIds, ...remoteIds};
    if (merged.isNotEmpty) {
      state = state.copyWith(bookmarkedPostIds: merged);
    }
  }

  Future<Set<String>> _loadLocalBookmarks() async {
    final raw = await StorageService.getString(_bookmarksKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<Set<String>> _loadRemoteBookmarks() async {
    final client = maybeSupabase();
    if (client == null) return {};
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return {};

    try {
      final response = await client
          .from('bookmarks')
          .select('post_id')
          .or('user_id.eq.${resident.id},resident_id.eq.${resident.id}');
      final list = response as List<dynamic>;
      return list.map((e) => e['post_id'] as String).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> repost(String originalPostId) async {
    final original = state.posts
        .where((p) => p.id == originalPostId)
        .firstOrNull;
    if (original == null) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    await addPost(
      worldId: original.worldId,
      residentId: resident.id,
      residentName: resident.name,
      residentAvatar: resident.avatarUrl,
      content: original.content,
      imageUri: original.imageUri,
      imageUris: original.imageUris,
      tierValue: resident.tier.value,
      repostOf: originalPostId,
    );
  }

  /// Loads a single post into the feed for deep links and notification targets.
  Future<bool> ensurePostVisible(String postId) async {
    if (state.posts.any((p) => p.id == postId)) return true;
    if (!isSupabaseConfigured()) return false;
    try {
      final row = await getSupabase()
          .from('posts')
          .select()
          .eq('id', postId)
          .maybeSingle();
      if (row == null) return false;
      final post = postFromJson(row);
      state = state.copyWith(
        posts: [
          post,
          ...state.posts.where((p) => p.id != postId),
        ],
      );
      _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  List<Post> getPostsByWorld(String worldId) {
    return sortNexusFeedPosts(
      state.posts.where((p) => p.worldId == worldId).toList(),
      FeedSort.hot,
    );
  }

  List<Post> getAllPosts() {
    return sortNexusFeedPosts(state.posts, FeedSort.hot);
  }

  List<Post> _sortPosts(Iterable<Post> source, {String sort = 'hot'}) {
    final feedSort = switch (sort) {
      'new' => FeedSort.latest,
      'top' => FeedSort.top,
      _ => FeedSort.hot,
    };
    return sortNexusFeedPosts(source.toList(), feedSort);
  }

  /// Keep optimistic / failed local posts across full feed reloads.
  List<Post> _mergeInFlightLocalPosts(List<Post> remote) {
    final remoteIds = remote.map((p) => p.id).toSet();
    final inFlight = state.posts.where((p) {
      final pending = p.syncStatus == SyncStatus.pending ||
          p.syncStatus == SyncStatus.error;
      if (!pending) return false;
      if (remoteIds.contains(p.id)) return false;
      final temp = p.localTempId;
      if (temp != null && remoteIds.contains(temp)) return false;
      return true;
    });
    if (inFlight.isEmpty) return remote;
    return _sortPosts([...inFlight, ...remote]).take(150).toList();
  }

  void setPosts(List<Post> posts) {
    state = state.copyWith(posts: posts);
    _persist();
  }

  Future<void> loadPosts() async {
    try {
      final hadCachedPosts = state.posts.isNotEmpty;
      // Don't wipe in-flight post errors while a create is still open.
      state = state.copyWith(
        isLoading: !hadCachedPosts,
        clearError: !state.isPosting,
      );
      if (!hadCachedPosts) {
        _currentLimit = 25;
        _lastCursor = null;
        _nexusCursor = null;
      }

      await _postsRepository.replayOutbox();

      final resident = ref.read(residentProvider).resident;
      final joinedWorldIds = resident?.joinedWorldIds
              .where(WorldService.isRemoteWorldId)
              .toList() ??
          <String>[];

      Set<String> mutualIds = {};
      if (joinedWorldIds.isNotEmpty && resident != null) {
        mutualIds = await _postsRepository.residentIdsInWorlds(
          joinedWorldIds,
          excludeResidentId: resident.id,
        );
      }

      final joinedResult = await _loadPostsFromJoinedWorlds();
      final posts = _mergeInFlightLocalPosts(joinedResult?.posts ?? []);

      state = state.copyWith(
        posts: posts,
        mutualWorldResidentIds: mutualIds,
        isLoading: false,
        error: joinedResult?.loadError,
        clearError: joinedResult?.loadError == null && !state.isPosting,
        hasMorePosts: joinedResult?.hasMore ?? false,
      );
      _persist();
    } catch (e) {
      final joinedResult = await _loadPostsFromJoinedWorlds();
      if (joinedResult != null) {
        state = state.copyWith(
          posts: _mergeInFlightLocalPosts(joinedResult.posts),
          error: joinedResult.loadError,
          clearError: joinedResult.loadError == null,
          isLoading: false,
        );
        _persist();
        return;
      }

      final raw = await StorageService.getString(StorageService.postsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        final posts = list
            .map((e) => postFromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(
          posts: posts,
          isLoading: false,
          clearError: true,
        );
        return;
      }
      state = state.copyWith(
        error: userFacingLoadError(
          e,
          fallback: 'Failed to load posts. Pull to refresh.',
        ),
        isLoading: false,
      );
    }
  }

  Future<void> loadMorePosts(String worldId) async {
    if (!_hasMore || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final remote = await _postsRepository.loadPosts(
        worldId: worldId,
        cursor: _lastCursor,
        limit: _currentLimit,
      );
      final newPosts = remote.items.map(postFromJson).toList();
      _hasMore = remote.hasMore;
      _lastCursor = remote.nextCursor;
      state = state.copyWith(
        posts: [...state.posts, ...newPosts],
        isLoadingMore: false,
        hasMorePosts: _hasMore,
      );
      _persist();
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> loadFollowingPosts() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final followingIds = resident.following.toList();
    if (followingIds.isEmpty) {
      state = state.copyWith(followingPosts: [], clearError: true);
      return;
    }

    try {
      final remote = await PostService.getFollowingPosts(
        resident.id,
        followingIds,
      );
      final posts = remote.map(postFromJson).toList();
      state = state.copyWith(followingPosts: posts, clearError: true);
    } catch (e) {
      state = state.copyWith(
        followingPosts: [],
        error: userFacingLoadError(
          e,
          fallback: 'Failed to load following feed. Pull to refresh.',
        ),
      );
    }
  }

  /// Subscribe to post changes for [worldId] only; pass null to unsubscribe.
  Future<void> setRealtimeWorldScope(String? worldId) async {
    _realtimeWorldId = worldId;
    if (worldId == null) {
      await clearRealtimeSubscriptions();
      return;
    }
    if (!_realtimePaused) {
      await _subscribeRealtime();
    }
  }

  /// Multi-world Nexus feed realtime (joined worlds).
  Future<void> setNexusRealtimeScope(Set<String> worldIds) async {
    _nexusWorldIds = worldIds
        .where(WorldService.isRemoteWorldId)
        .take(15)
        .toSet();
    if (_realtimePaused) return;
    await _subscribeNexusRealtime();
  }

  Future<void> setRealtimePaused(bool paused) async {
    _realtimePaused = paused;
    if (paused) {
      await clearRealtimeSubscriptions();
      await _clearNexusRealtimeSubscriptions();
    } else {
      if (_realtimeWorldId != null) {
        await _subscribeRealtime();
      }
      if (_nexusWorldIds.isNotEmpty) {
        await _subscribeNexusRealtime();
      }
    }
  }

  Future<void> clearRealtimeSubscriptions() async {
    await _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  Future<void> _clearNexusRealtimeSubscriptions() async {
    await _nexusRealtimeChannel?.unsubscribe();
    _nexusRealtimeChannel = null;
  }

  void _mergeRealtimePost(
    Post? post, {
    bool isDelete = false,
    String? deletedId,
  }) {
    if (isDelete) {
      final id = deletedId;
      if (id == null) return;
      state = state.copyWith(
        posts: state.posts.where((p) => p.id != id).toList(),
      );
      _persist();
      return;
    }

    if (post == null || post.status != 'published') return;
    if (state.scheduledPosts.any((p) => p.id == post.id)) return;

    // Drop optimistic local copy when realtime delivers the server row.
    final withoutLocalDup = state.posts.where((p) {
      if (p.id == post.id) return true;
      final pending = p.syncStatus == SyncStatus.pending ||
          p.syncStatus == SyncStatus.error;
      if (!pending) return true;
      if (p.localTempId != null && p.localTempId == post.id) return false;
      if (p.residentId == post.residentId &&
          p.content == post.content &&
          (p.timestamp - post.timestamp).abs() < 120000) {
        return false;
      }
      return true;
    }).toList();

    final existingIndex = withoutLocalDup.indexWhere((p) => p.id == post.id);
    if (existingIndex == -1) {
      state = state.copyWith(posts: [post, ...withoutLocalDup]);
    } else {
      final posts = List<Post>.from(withoutLocalDup);
      posts[existingIndex] = post;
      state = state.copyWith(posts: posts);
    }
    _persist();
  }

  Future<void> _subscribeRealtime() async {
    final client = maybeSupabase();
    if (client == null || _realtimePaused) return;

    final worldId = _realtimeWorldId;
    if (worldId == null) {
      await clearRealtimeSubscriptions();
      return;
    }

    await _realtimeChannel?.unsubscribe();

    _realtimeChannel = client
        .channel('posts_realtime_$worldId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'world_id',
            value: worldId,
          ),
          callback: (payload) {
            _mergeRealtimePost(postFromJson(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'posts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'world_id',
            value: worldId,
          ),
          callback: (payload) {
            _mergeRealtimePost(postFromJson(payload.newRecord));
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'posts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'world_id',
            value: worldId,
          ),
          callback: (payload) {
            _mergeRealtimePost(
              null,
              isDelete: true,
              deletedId: payload.oldRecord['id'] as String?,
            );
          },
        )
        .subscribe();
  }

  Future<void> _subscribeNexusRealtime() async {
    final client = maybeSupabase();
    if (client == null || _realtimePaused || _nexusWorldIds.isEmpty) return;

    await _nexusRealtimeChannel?.unsubscribe();

    var channel = client.channel('nexus_posts_${_nexusWorldIds.length}');
    for (final worldId in _nexusWorldIds) {
      channel = channel
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'posts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'world_id',
              value: worldId,
            ),
            callback: (payload) {
              _mergeRealtimePost(
                postFromJson(payload.newRecord),
              );
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'posts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'world_id',
              value: worldId,
            ),
            callback: (payload) {
              _mergeRealtimePost(
                postFromJson(payload.newRecord),
              );
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.delete,
            schema: 'public',
            table: 'posts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'world_id',
              value: worldId,
            ),
            callback: (payload) {
              _mergeRealtimePost(
                null,
                isDelete: true,
                deletedId: payload.oldRecord['id'] as String?,
              );
            },
          );
    }
    _nexusRealtimeChannel = channel.subscribe();
  }

  Future<void> loadMoreNexusPosts() async {
    if (!_nexusHasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final joinedResult = await _loadPostsFromJoinedWorlds(append: true);
      if (joinedResult == null) {
        state = state.copyWith(isLoadingMore: false);
        return;
      }
      state = state.copyWith(
        posts: _mergeInFlightLocalPosts(joinedResult.posts),
        isLoadingMore: false,
        hasMorePosts: joinedResult.hasMore,
        error: joinedResult.loadError,
        clearError: joinedResult.loadError == null,
      );
      _persist();
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<({List<Post> posts, String? loadError, bool hasMore})?> _loadPostsFromJoinedWorlds({
    bool append = false,
  }) async {
    final joinedWorldIds = ref
        .read(residentProvider)
        .resident
        ?.joinedWorldIds
        .where(WorldService.isRemoteWorldId)
        .toSet()
        .toList();
    if (joinedWorldIds == null || joinedWorldIds.isEmpty) return null;

    final nexusResult = await _postsRepository.loadNexusPosts(
      cursor: append ? _nexusCursor : null,
    );

    // Successful Nexus response (including empty feed) — do not treat empty as error.
    if (nexusResult != null && (nexusResult.items.isNotEmpty || !append)) {
      _nexusCursor = nexusResult.nextCursor;
      _nexusHasMore = nexusResult.hasMore;

      final fetched = nexusResult.items.map(postFromJson).toList();
      final merged = append
          ? _sortPosts([...state.posts, ...fetched]).take(150).toList()
          : _sortPosts(fetched).take(150).toList();

      return (
        posts: merged,
        loadError: null,
        hasMore: nexusResult.hasMore,
      );
    }

    // Fallback when Nexus RPC is unavailable.
    final posts = append ? List<Post>.from(state.posts) : <Post>[];
    var failures = 0;
    var anyHasMore = false;
    for (final worldId in joinedWorldIds) {
      try {
        final result = await _postsRepository.loadPosts(
          worldId: worldId,
          limit: _currentLimit,
        );
        posts.addAll(result.items.map(postFromJson));
        if (result.hasMore) anyHasMore = true;
      } catch (_) {
        failures++;
      }
    }

    _nexusHasMore = anyHasMore;

    final sorted = posts.isEmpty
        ? <Post>[]
        : _sortPosts(posts).take(150).toList();

    String? loadError;
    if (failures > 0 && failures == joinedWorldIds.length) {
      loadError =
          'Could not load posts from your worlds. Pull to refresh.';
    } else if (failures > 0 && sorted.isNotEmpty) {
      loadError = 'Some worlds could not be loaded.';
    }

    return (posts: sorted, loadError: loadError, hasMore: anyHasMore);
  }

  void _persist() {
    final json = jsonEncode(state.posts.map(postToJson).toList());
    StorageService.setStringDebounced(StorageService.postsKey, json);
  }

  void clearForSignOut() {
    unawaited(_realtimeChannel?.unsubscribe());
    _realtimeChannel = null;
    unawaited(_nexusRealtimeChannel?.unsubscribe());
    _nexusRealtimeChannel = null;
    _schedulerTimer?.cancel();
    _userReactions.clear();
    _hasMore = true;
    _nexusHasMore = true;
    _lastCursor = null;
    _nexusCursor = null;
    _currentLimit = 20;
    state = const PostState();
  }
}


