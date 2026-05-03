import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../models/resident.dart';
import '../models/notification.dart';
import '../services/permission_service.dart';
import 'world_provider.dart';
import '../services/storage_service.dart';
import '../utils/id_generator.dart';
import 'resident_provider.dart';
import 'notification_provider.dart';
import 'quest_provider.dart';

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

class PostNotifier extends StateNotifier<PostState> {
  final Ref _ref;

  PostNotifier(this._ref) : super(const PostState());

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
  }) async {
    final resident = _ref.read(residentProvider).resident;
    if (resident == null) return;
    final world = _ref.read(worldProvider).worlds[worldId];
    if (!WorldPermissions.canPost(resident, worldId, world?.sovereignId)) return;

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
    );

    state = state.copyWith(posts: [post, ...state.posts]);
    _persist();

    _ref.read(residentProvider.notifier).addRep(worldId, 5);
    _ref.read(questProvider.notifier).onPostCreated();
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

    _ref.read(questProvider.notifier).onReacted();
    _ref.read(notificationProvider.notifier).addNotification(
          type: NotificationType.like,
          message: 'Someone reacted to your post',
          postId: postId,
          worldId: null,
        );
  }

  void editPost(String postId, String newContent) {
    final posts = state.posts.map((p) {
      if (p.id == postId) return p.copyWith(content: newContent, isEdited: true);
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
      bookmarkedPostIds: state.bookmarkedPostIds.where((id) => id != postId).toSet(),
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

    _ref.read(questProvider.notifier).onCommentAdded();
    _ref.read(residentProvider.notifier).addRep(post.worldId, 3);
    _ref.read(notificationProvider.notifier).addNotification(
          type: NotificationType.comment,
          message: 'Someone commented on your post',
          postId: postId,
          worldId: post.worldId,
        );
  }

  // ── Bookmark ────────────────────────────────────────────────

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

  // ── Repost ──────────────────────────────────────────────────

  void repost(String originalPostId) {
    final original = state.posts.where((p) => p.id == originalPostId).firstOrNull;
    if (original == null) return;

    final resident = _ref.read(residentProvider).resident;
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

    _ref.read(residentProvider.notifier).addRep(original.worldId, 5);
    _ref.read(questProvider.notifier).onPostCreated();

    _ref.read(notificationProvider.notifier).addNotification(
          type: NotificationType.like,
          message: '${resident.name} reposted your post',
          postId: originalPostId,
          worldId: original.worldId,
        );
  }

  // ── Query ──────────────────────────────────────────────────

  List<Post> getPostsByWorld(String worldId) {
    final worldPosts = state.posts.where((p) => p.worldId == worldId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final pinned = worldPosts.where((p) => p.isPinned).toList();
    final announcements = worldPosts.where((p) => !p.isPinned && p.isAnnouncement).toList();
    final regular = worldPosts.where((p) => !p.isPinned && !p.isAnnouncement).toList();
    return [...pinned, ...announcements, ...regular];
  }

  List<Post> getAllPosts() {
    final sorted = List.of(state.posts)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final pinned = sorted.where((p) => p.isPinned).toList();
    final announcements = sorted.where((p) => !p.isPinned && p.isAnnouncement).toList();
    final regular = sorted.where((p) => !p.isPinned && !p.isAnnouncement).toList();
    return [...pinned, ...announcements, ...regular];
  }

  void setPosts(List<Post> posts) {
    state = state.copyWith(posts: posts);
    _persist();
  }

  Future<void> loadPosts() async {
    try {
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
    return Post(
      id: json['id'] ?? '',
      worldId: json['worldId'] ?? '',
      residentId: json['residentId'] ?? '',
      residentName: json['residentName'] ?? '',
      residentAvatar: json['residentAvatar'] ?? '',
      content: json['content'] ?? '',
      imageUri: json['imageUri'],
      imageUris: (json['imageUris'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      timestamp: json['timestamp'] ?? 0,
      tierAtPosting: ResidentTier.fromValue(json['tierAtPosting'] ?? 1),
      reactions: Map<String, int>.from(json['reactions'] ?? {}),
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => Comment(
                    id: c['id'] ?? '',
                    residentId: c['residentId'] ?? '',
                    residentName: c['residentName'] ?? '',
                    content: c['content'] ?? '',
                    timestamp: c['timestamp'] ?? 0,
                  ))
              .toList() ??
          [],
      isAnnouncement: json['isAnnouncement'] ?? false,
      isPinned: json['isPinned'] ?? false,
      isEdited: json['isEdited'] ?? false,
      repostOf: json['repostOf'],
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
        'comments': p.comments
            .map((c) => {
                  'id': c.id,
                  'residentId': c.residentId,
                  'residentName': c.residentName,
                  'content': c.content,
                  'timestamp': c.timestamp,
                })
            .toList(),
      };
}

final postProvider = StateNotifierProvider<PostNotifier, PostState>(
  (ref) => PostNotifier(ref),
);
