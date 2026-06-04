import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
import '../models/resident.dart';
import '../models/world.dart';
import '../models/notification.dart';
import '../models/sync_status.dart';
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
import '../repositories/post_repository.dart';
import '../utils/id_generator.dart';
import '../utils/text_parser.dart';
import '../utils/haptics.dart';
import '../utils/provider_errors.dart';
import '../utils/rate_limiter.dart';
import '../config/achievements.dart';
import 'resident_provider.dart';
import 'notification_provider.dart';
import 'quest_provider.dart';
import 'achievement_provider.dart';

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

class PostNotifier extends Notifier<PostState> {
  final PostRepository _postsRepository = const PostRepository();
  RealtimeChannel? _realtimeChannel;
  Timer? _schedulerTimer;
  final Map<String, Set<String>> _userReactions = {};
  int _lastPersistedCount = 0;
  int _currentLimit = 20;
  String? _lastCursor;
  bool _hasMore = true;

  @override
  PostState build() {
    ref.onDispose(() {
      unawaited(_realtimeChannel?.unsubscribe());
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
    return const PostState();
  }

  static const String _scheduledKey = '@scheduled_posts';

  Future<void> _loadScheduledPosts() async {
    try {
      final raw = await StorageService.getString(_scheduledKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      final posts = list
          .map((e) => _postFromJson(e as Map<String, dynamic>))
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
    final json = jsonEncode(state.scheduledPosts.map(_postToJson).toList());
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
    if (!resident.joinedWorldIds.contains(worldId)) {
      state = state.copyWith(isPosting: false);
      return;
    }

    final world = ref.read(worldProvider).worlds[worldId];
    final constitution = world?.constitution ?? const WorldConstitution();
    if (!WorldPermissions.canPost(
      resident,
      worldId,
      world?.sovereignId,
      constitution: constitution,
    )) {
      state = state.copyWith(isPosting: false);
      return;
    }
    if (WorldPermissions.isMuted(resident, worldId)) {
      state = state.copyWith(isPosting: false);
      return;
    }

    final mentions = TextParser.extractMentions(content);
    final hashtags = TextParser.extractHashtags(content);

    final moderationResult = ModerationFilter.checkContent(content);
    final postStatus = moderationResult != null
        ? 'pending_review'
        : 'published';

    final post = Post(
      id: generateId(),
      worldId: worldId,
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
      state = state.copyWith(
        scheduledPosts: [...state.scheduledPosts, post],
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
      state = state.copyWith(
        posts: state.posts.map((p) {
          if (p.id != post.id) return p;
          return p.copyWith(
            imageUri: cloudImageUrl ?? p.imageUri,
            imageUris: syncedUris ?? p.imageUris,
            syncStatus: SyncStatus.synced,
            clearSyncError: true,
          );
        }).toList(),
        isPosting: false,
        clearLastError: true,
      );
      unawaited(
        AnalyticsService.logEvent(
          AnalyticsEvents.postCreated,
          parameters: {'world_id': worldId},
        ),
      );
      ref.read(residentProvider.notifier).addRep(worldId, 5);
      _checkPostMilestones(residentId);
      _triggerPrestigeUpdate(worldId);
    } else if (result.queued) {
      state = state.copyWith(
        isPosting: false,
        lastError: 'Post queued for sync',
      );
    } else {
      state = state.copyWith(
        posts: state.posts.map((p) {
          if (p.id != post.id) return p;
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

    ref.read(residentProvider.notifier).awardActivityXp('post', 5);
    ref.read(questProvider.notifier).onPostCreated();
    Haptics.medium();
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

  static const _voteKeys = {'upvote', 'downvote'};

  /// Toggles a reaction (RPC is toggle on server). Handles vote exclusivity.
  void toggleReaction(String postId, String reactionKey, String residentId) {
    if (!RateLimiter.canProceed('reaction_$postId')) return;
    final userSet = _userReactions.putIfAbsent(postId, () => {});
    final wasActive = userSet.contains(reactionKey);

    if (!wasActive) {
      for (final other in _voteKeys) {
        if (other != reactionKey && userSet.contains(other)) {
          _applyReactionDelta(postId, other, -1);
          userSet.remove(other);
        }
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

    unawaited(
      _postsRepository.addReaction(
        postId: postId,
        emoji: reactionKey,
        residentId: residentId,
      ),
    );

    if (!wasActive) {
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
              postId: postId,
              worldId: reactedPost.worldId,
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
    toggleReaction(postId, emoji, residentId);
  }

  void _applyReactionDelta(String postId, String reactionKey, int delta) {
    final posts = state.posts.map((p) {
      if (p.id != postId) return p;
      final reactions = Map<String, int>.from(p.reactions);
      final next = (reactions[reactionKey] ?? 0) + delta;
      if (next <= 0) {
        reactions.remove(reactionKey);
      } else {
        reactions[reactionKey] = next;
      }
      return p.copyWith(reactions: reactions);
    }).toList();
    state = state.copyWith(posts: posts);
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
    final posts = state.posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(content: newContent, isEdited: true);
      }
      return p;
    }).toList();
    state = state.copyWith(posts: posts);
    _persist();
    unawaited(_postsRepository.editPost(postId: postId, content: newContent));
  }

  void togglePin(String postId) {
    final current = state.posts.where((p) => p.id == postId).firstOrNull;
    final nextPinned = !(current?.isPinned ?? false);
    final posts = state.posts.map((p) {
      if (p.id == postId) return p.copyWith(isPinned: nextPinned);
      return p;
    }).toList();
    state = state.copyWith(posts: posts);
    _persist();
    unawaited(_postsRepository.setPinned(postId: postId, isPinned: nextPinned));
  }

  void deletePost(String postId) {
    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
      bookmarkedPostIds: state.bookmarkedPostIds
          .where((id) => id != postId)
          .toSet(),
    );
    _persist();
    _persistBookmarks();
    unawaited(_postsRepository.deletePost(postId));
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
    ref
        .read(notificationProvider.notifier)
        .addNotification(
          type: NotificationType.comment,
          message: 'Someone commented on your post',
          postId: postId,
          worldId: post.worldId,
        );
  }

  void voteOnPoll(String postId, String pollOptionId) {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

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
        _postsRepository.votePoll(
          post: updatedPost,
          poll: updatedPoll,
          residentId: resident.id,
        ),
      );
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
    if (awardedPost != null) {
      ref
          .read(notificationProvider.notifier)
          .addNotification(
            type: NotificationType.like,
            message: 'Someone gave your post an award!',
            postId: postId,
            worldId: awardedPost.worldId,
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

  void repost(String originalPostId) {
    final original = state.posts
        .where((p) => p.id == originalPostId)
        .firstOrNull;
    if (original == null) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final repost = Post(
      id: generateId(),
      worldId: original.worldId,
      residentId: resident.id,
      residentName: resident.name,
      residentAvatar: resident.avatarUrl,
      content: original.content,
      imageUri: original.imageUri,
      imageUris: original.imageUris,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      tierAtPosting: resident.tier,
      repostOf: originalPostId,
    );

    state = state.copyWith(posts: [repost, ...state.posts]);
    _persist();

    ref.read(questProvider.notifier).onPostCreated();

    ref
        .read(notificationProvider.notifier)
        .addNotification(
          type: NotificationType.like,
          message: '${resident.name} reposted your post',
          postId: originalPostId,
          worldId: original.worldId,
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
      final post = _postFromJson(row as Map<String, dynamic>);
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
    return _sortPosts(state.posts.where((p) => p.worldId == worldId));
  }

  List<Post> getAllPosts() {
    return _sortPosts(state.posts);
  }

  List<Post> _sortPosts(Iterable<Post> source, {String sort = 'hot'}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final decreeExpiry = const Duration(hours: 24).inMilliseconds;

    // List.of(source) creates a new mutable copy; sort() mutates this copy,
    // not the original source iterable, so the caller's data is unaffected.
    final posts = List.of(source);

    int priority(Post p) {
      if (p.isDecree && (now - p.timestamp) < decreeExpiry) return 0;
      if (p.isPinned && !p.isDecree) return 1;
      if (p.isAnnouncement && !p.isPinned && !p.isDecree) return 2;
      return 3;
    }

    int compareByReactions(Post a, Post b) {
      final aTotal = a.reactions.values.fold<int>(0, (s, c) => s + c);
      final bTotal = b.reactions.values.fold<int>(0, (s, c) => s + c);
      return bTotal.compareTo(aTotal);
    }

    int compareByHot(Post a, Post b) {
      final aScore = _hotScore(a);
      final bScore = _hotScore(b);
      return bScore.compareTo(aScore);
    }

    posts.sort((a, b) {
      final pa = priority(a);
      final pb = priority(b);
      if (pa != pb) return pa.compareTo(pb);
      if (pa == 3) {
        switch (sort) {
          case 'new':
            return b.timestamp.compareTo(a.timestamp);
          case 'top':
            return compareByReactions(a, b);
          case 'hot':
          default:
            return compareByHot(a, b);
        }
      }
      return b.timestamp.compareTo(a.timestamp);
    });

    return posts;
  }

  double _hotScore(Post post) {
    final totalReactions =
        post.reactions.values.fold<int>(0, (s, c) => s + c) +
        post.comments.length;
    final ageMs = DateTime.now().millisecondsSinceEpoch - post.timestamp;
    final ageHours = ageMs / (1000 * 60 * 60);
    return totalReactions / math.pow(ageHours + 2, 1.5);
  }

  void setPosts(List<Post> posts) {
    state = state.copyWith(posts: posts);
    _persist();
  }

  Future<void> loadPosts() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);
      _currentLimit = 25;
      _lastCursor = null;
      _hasMore = false;

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
      final posts = joinedResult?.posts ?? [];

      state = state.copyWith(
        posts: posts,
        mutualWorldResidentIds: mutualIds,
        isLoading: false,
        error: joinedResult?.loadError,
        clearError: joinedResult?.loadError == null,
        hasMorePosts: false,
      );
      _persist();
      unawaited(_subscribeRealtime());
    } catch (e) {
      final joinedResult = await _loadPostsFromJoinedWorlds();
      if (joinedResult != null) {
        state = state.copyWith(
          posts: joinedResult.posts,
          error: joinedResult.loadError,
          clearError: joinedResult.loadError == null,
          isLoading: false,
        );
        _persist();
        unawaited(_subscribeRealtime());
        return;
      }

      final raw = await StorageService.getString(StorageService.postsKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        final posts = list
            .map((e) => _postFromJson(e as Map<String, dynamic>))
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
      final newPosts = remote.items.map(_postFromJson).toList();
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
      final posts = remote.map(_postFromJson).toList();
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

  Future<void> _subscribeRealtime() async {
    final client = maybeSupabase();
    if (client == null) return;

    await _realtimeChannel?.unsubscribe();

    _realtimeChannel = client
        .channel('posts_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            final newPost = _postFromJson(payload.newRecord);
            if (state.posts.any((p) => p.id == newPost.id)) return;
            if (state.scheduledPosts.any((p) => p.id == newPost.id)) return;
            state = state.copyWith(posts: [newPost, ...state.posts]);
            _persist();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            final updated = _postFromJson(payload.newRecord);
            final posts = state.posts.map((p) {
              if (p.id == updated.id) return updated;
              return p;
            }).toList();
            state = state.copyWith(posts: posts);
            _persist();
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            final deletedId = payload.oldRecord['id'] as String?;
            if (deletedId == null) return;
            state = state.copyWith(
              posts: state.posts.where((p) => p.id != deletedId).toList(),
            );
            _persist();
          },
        )
        .subscribe();
  }

  Future<({List<Post> posts, String? loadError})?> _loadPostsFromJoinedWorlds() async {
    final joinedWorldIds = ref
        .read(residentProvider)
        .resident
        ?.joinedWorldIds
        .where(WorldService.isRemoteWorldId)
        .toSet()
        .toList();
    if (joinedWorldIds == null || joinedWorldIds.isEmpty) return null;

    final posts = <Post>[];
    var failures = 0;
    for (final worldId in joinedWorldIds) {
      try {
        final result = await _postsRepository.loadPosts(
          worldId: worldId,
          limit: _currentLimit,
        );
        posts.addAll(result.items.map(_postFromJson));
      } catch (_) {
        failures++;
      }
    }

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

    return (posts: sorted, loadError: loadError);
  }

  static Post _postFromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final createdAt = json['created_at'];

    return Post(
      id: json['id'] ?? '',
      worldId: json['worldId'] ?? json['world_id'] ?? '',
      residentId:
          json['residentId'] ?? json['resident_id'] ?? json['author_id'] ?? '',
      residentName:
          json['residentName'] ??
          json['resident_name'] ??
          json['author_name'] ??
          '',
      authorDisplayTitle:
          json['authorDisplayTitle'] ??
          json['author_display_title'] as String?,
      residentAvatar:
          json['residentAvatar'] ??
          json['resident_avatar'] ??
          json['author_avatar'] ??
          '',
      content: json['content'] ?? '',
      imageUri: json['imageUri'] ?? json['image_url'],
      imageUris:
          media ??
          (json['imageUris'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      timestamp:
          json['timestamp'] ??
          (createdAt is int
              ? createdAt
              : DateTime.tryParse(
                      createdAt?.toString() ?? '',
                    )?.millisecondsSinceEpoch ??
                    0),
      tierAtPosting: ResidentTier.fromValue(
        json['tierAtPosting'] ?? json['tier_at_posting'] ?? 1,
      ),
      reactions: Map<String, int>.from(json['reactions'] ?? {}),
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map(
                (c) => Comment(
                  id: c['id'] ?? '',
                  residentId: c['residentId'] ?? '',
                  residentName: c['residentName'] ?? '',
                  content: c['content'] ?? '',
                  timestamp: c['timestamp'] ?? 0,
                  parentId: c['parentId'],
                  tierAtPosting: c['tierAtPosting'] ?? 1,
                ),
              )
              .toList() ??
          [],
      isAnnouncement:
          json['isAnnouncement'] ?? json['is_announcement'] ?? false,
      isPinned: json['isPinned'] ?? json['is_pinned'] ?? false,
      isEdited: json['isEdited'] ?? json['is_edited'] ?? false,
      repostOf: json['repostOf'],
      mentions:
          (json['mentions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hashtags:
          (json['hashtags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      poll: json['poll'] != null
          ? Poll.fromJson(json['poll'] as Map<String, dynamic>)
          : null,
      status: json['status'] ?? 'published',
      isDecree: json['isDecree'] ?? json['is_decree'] ?? false,
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.tryParse(json['scheduledFor'] as String)
          : null,
      awards:
          (json['awards'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      failedPublishes: json['failedPublishes'] ?? 0,
      syncStatus: SyncStatusJson.fromJson(json['syncStatus']),
      localTempId: json['localTempId'] as String?,
      syncError: json['syncError'] as String?,
    );
  }

  void _persist() {
    final json = jsonEncode(state.posts.map(_postToJson).toList());
    StorageService.setStringDebounced(StorageService.postsKey, json);
  }

  static Map<String, dynamic> _postToJson(Post p) => {
    'id': p.id,
    'worldId': p.worldId,
    'residentId': p.residentId,
    'residentName': p.residentName,
    'residentAvatar': p.residentAvatar,
    'content': p.content,
    'imageUri': p.imageUri,
    'imageUris': p.imageUris,
    'timestamp': p.timestamp,
    'tierAtPosting': p.tierAtPosting.value,
    'reactions': p.reactions,
    'isAnnouncement': p.isAnnouncement,
    'isPinned': p.isPinned,
    'isEdited': p.isEdited,
    'repostOf': p.repostOf,
    'mentions': p.mentions,
    'hashtags': p.hashtags,
    'poll': p.poll?.toJson(),
    'isDecree': p.isDecree,
    'status': p.status,
    'scheduledFor': p.scheduledFor?.toIso8601String(),
    'awards': p.awards,
    'failedPublishes': p.failedPublishes,
    'syncStatus': p.syncStatus.value,
    'localTempId': p.localTempId,
    'syncError': p.syncError,
    'comments': p.comments
        .map(
          (c) => {
            'id': c.id,
            'residentId': c.residentId,
            'residentName': c.residentName,
            'content': c.content,
            'timestamp': c.timestamp,
            'parentId': c.parentId,
            'tierAtPosting': c.tierAtPosting,
          },
        )
        .toList(),
  };

  void clearForSignOut() {
    unawaited(_realtimeChannel?.unsubscribe());
    _realtimeChannel = null;
    _schedulerTimer?.cancel();
    state = const PostState();
  }
}

final postProvider = NotifierProvider<PostNotifier, PostState>(
  PostNotifier.new,
);
