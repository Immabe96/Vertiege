import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../models/resident.dart';
import '../models/notification.dart';
import '../services/storage_service.dart';
import '../utils/id_generator.dart';
import 'resident_provider.dart';
import 'notification_provider.dart';

class PostState {
  final List<Post> posts;
  const PostState({this.posts = const []});

  PostState copyWith({List<Post>? posts}) => PostState(posts: posts ?? this.posts);
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
    int tierValue = 1,
  }) async {
    final post = Post(
      id: generateId(),
      worldId: worldId,
      residentId: residentId,
      residentName: residentName,
      residentAvatar: residentAvatar,
      content: content,
      imageUri: imageUri,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      tierAtPosting: ResidentTier.fromValue(tierValue),
    );

    state = state.copyWith(posts: [post, ...state.posts]);
    _persist();

    _ref.read(residentProvider.notifier).addRep(worldId, 5);
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

    _ref.read(notificationProvider.notifier).addNotification(
          type: NotificationType.like,
          message: 'Someone reacted to your post',
          postId: postId,
          worldId: null,
        );
  }

  void deletePost(String postId) {
    state = state.copyWith(posts: state.posts.where((p) => p.id != postId).toList());
    _persist();
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

    _ref.read(residentProvider.notifier).addRep(comment.residentId, 3);
    _ref.read(notificationProvider.notifier).addNotification(
          type: NotificationType.comment,
          message: 'Someone commented on your post',
          postId: postId,
          worldId: post.worldId,
        );
  }

  List<Post> getPostsByWorld(String worldId) {
    return state.posts.where((p) => p.worldId == worldId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<Post> getAllPosts() {
    return List.of(state.posts)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void setPosts(List<Post> posts) {
    state = state.copyWith(posts: posts);
    _persist();
  }

  Future<void> loadPosts() async {
    final raw = await StorageService.getString(StorageService.postsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final posts = list.map((e) => _postFromJson(e)).toList();
      state = state.copyWith(posts: posts);
    } catch (_) {}
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
        'timestamp': p.timestamp,
        'tierAtPosting': p.tierAtPosting.value,
        'reactions': p.reactions,
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
