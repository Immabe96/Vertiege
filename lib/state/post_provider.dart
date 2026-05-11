import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../models/resident.dart';
import '../models/world.dart';
import '../models/notification.dart';
import '../services/moderation_filter.dart';
import '../services/permission_service.dart';
import 'world_provider.dart';
import '../services/storage_service.dart';
import '../services/media_service.dart';
import '../services/post_service.dart';
import '../utils/id_generator.dart';
import '../utils/text_parser.dart';
import '../utils/haptics.dart';
import 'resident_provider.dart';
import 'notification_provider.dart';
import 'quest_provider.dart';
import 'achievement_provider.dart';

class PostState {
  final List<Post> posts;
  final Set<String> bookmarkedPostIds;
  final String? error;

  const PostState({
    this.posts = const [],
    this.bookmarkedPostIds = const {},
    this.error,
  });

  bool get hasError => error != null;

  PostState copyWith({
    List<Post>? posts,
    Set<String>? bookmarkedPostIds,
    String? error,
    bool clearError = false,
  }) => PostState(
    posts: posts ?? this.posts,
    bookmarkedPostIds: bookmarkedPostIds ?? this.bookmarkedPostIds,
    error: clearError ? null : error ?? this.error,
  );
}

class PostNotifier extends Notifier<PostState> {
  @override
  PostState build() => const PostState();

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
  }) async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;
    final world = ref.read(worldProvider).worlds[worldId];
    final constitution = world?.constitution ?? const WorldConstitution();
    if (!WorldPermissions.canPost(
      resident,
      worldId,
      world?.sovereignId,
      constitution: constitution,
    )) {
      return;
    }
    if (WorldPermissions.isMuted(resident, worldId)) return;

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
    );

    // Upload image to Supabase Storage if local file
    String? cloudImageUrl = imageUri;
    if (imageUri != null && !imageUri.startsWith('http')) {
      cloudImageUrl = await MediaService.uploadPostImage(imageUri, residentId);
    }

    state = state.copyWith(posts: [post, ...state.posts]);
    _persist();

    await PostService.createPost(
      residentId: residentId,
      residentName: residentName,
      worldId: worldId,
      content: content,
      imageUrl: cloudImageUrl,
      residentAvatar: residentAvatar,
      tierAtPosting: tierValue,
      isAnnouncement: isAnnouncement,
    );

    ref.read(residentProvider.notifier).addRep(worldId, 5);
    ref.read(questProvider.notifier).onPostCreated();
    Haptics.medium();
    _checkPostMilestones(residentId);
    _triggerPrestigeUpdate(worldId);
  }

  void _checkPostMilestones(String residentId) {
    final postCount = state.posts
        .where((p) => p.residentId == residentId)
        .length;
    final notifier = ref.read(achievementProvider.notifier);
    if (postCount >= 1) notifier.autoAwardAchievement('pioneer-poster');
    if (postCount >= 10) notifier.autoAwardAchievement('voice-of-realm');
    if (postCount >= 50) notifier.autoAwardAchievement('chronicler');
    if (postCount >= 100) notifier.autoAwardAchievement('nexus-scribe');
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

  void addReaction(String postId, String emoji, String residentId) {
    final posts = state.posts.map((p) {
      if (p.id != postId) return p;
      final reactions = Map<String, int>.from(p.reactions);
      reactions[emoji] = (reactions[emoji] ?? 0) + 1;
      return p.copyWith(reactions: reactions);
    }).toList();

    state = state.copyWith(posts: posts);
    _persist();

    // Persist to Supabase
    PostService.addReaction(postId, emoji, residentId);

    final reactedPost = state.posts.where((p) => p.id == postId).firstOrNull;
    ref.read(questProvider.notifier).onReacted();
    ref
        .read(notificationProvider.notifier)
        .addNotification(
          type: NotificationType.like,
          message: 'Someone reacted to your post',
          postId: postId,
          worldId: reactedPost?.worldId,
        );

    if (reactedPost != null) {
      final totalReactions = reactedPost.reactions.values.fold<int>(
        0,
        (sum, c) => sum + c,
      );
      ref
          .read(notificationProvider.notifier)
          .reactionMilestone(
            postId: postId,
            worldId: reactedPost.worldId,
            count: totalReactions,
          );
    }
  }

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
  }

  void togglePin(String postId) {
    final posts = state.posts.map((p) {
      if (p.id == postId) return p.copyWith(isPinned: !p.isPinned);
      return p;
    }).toList();
    state = state.copyWith(posts: posts);
    _persist();
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

    // Persist to Supabase
    PostService.addComment(postId, comment.residentId, comment.content);

    ref.read(questProvider.notifier).onCommentAdded();
    ref.read(residentProvider.notifier).addRep(post.worldId, 3);
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

  void _bookmark(String postId) {
    final updated = {...state.bookmarkedPostIds, postId};
    state = state.copyWith(bookmarkedPostIds: updated);
    _persistBookmarks();
  }

  void _unbookmark(String postId) {
    final updated = state.bookmarkedPostIds.where((id) => id != postId).toSet();
    state = state.copyWith(bookmarkedPostIds: updated);
    _persistBookmarks();
  }

  bool isBookmarked(String postId) => state.bookmarkedPostIds.contains(postId);

  Future<void> _persistBookmarks() async {
    final json = jsonEncode(state.bookmarkedPostIds.toList());
    await StorageService.setString(_bookmarksKey, json);
  }

  Future<void> loadBookmarks() async {
    final raw = await StorageService.getString(_bookmarksKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      state = state.copyWith(
        bookmarkedPostIds: list.map((e) => e.toString()).toSet(),
      );
    } catch (_) {}
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

    ref.read(residentProvider.notifier).addRep(original.worldId, 5);
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

  List<Post> getPostsByWorld(String worldId) {
    return _sortPosts(state.posts.where((p) => p.worldId == worldId));
  }

  List<Post> getAllPosts() {
    return _sortPosts(state.posts);
  }

  List<Post> _sortPosts(Iterable<Post> source) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final decreeExpiry = const Duration(hours: 24).inMilliseconds;

    final sorted = List.of(source)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final activeDecrees = sorted
        .where((p) => p.isDecree && (now - p.timestamp) < decreeExpiry)
        .toList();
    final pinned = sorted.where((p) => p.isPinned && !p.isDecree).toList();
    final announcements = sorted
        .where((p) => !p.isPinned && p.isAnnouncement && !p.isDecree)
        .toList();
    final regular = sorted
        .where((p) => !p.isPinned && !p.isAnnouncement && !p.isDecree)
        .toList();
    return [...activeDecrees, ...pinned, ...announcements, ...regular];
  }

  void setPosts(List<Post> posts) {
    state = state.copyWith(posts: posts);
    _persist();
  }

  Future<void> loadPosts() async {
    try {
      // Fetch from Supabase first
      final remote = await PostService.getPosts();
      if (remote.isNotEmpty) {
        final posts = remote.map((e) => _postFromJson(e)).toList();
        state = state.copyWith(posts: posts, clearError: true);
        _persist();
        return;
      }
      // Fallback to local cache
      final raw = await StorageService.getString(StorageService.postsKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw) as List<dynamic>;
      final posts = list.map((e) => _postFromJson(e)).toList();
      state = state.copyWith(posts: posts, clearError: true);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load posts: $e');
    }
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
    'comments': p.comments
        .map(
          (c) => {
            'id': c.id,
            'residentId': c.residentId,
            'residentName': c.residentName,
            'content': c.content,
            'timestamp': c.timestamp,
          },
        )
        .toList(),
  };
}

final postProvider = NotifierProvider<PostNotifier, PostState>(
  PostNotifier.new,
);
