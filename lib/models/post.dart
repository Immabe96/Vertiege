import 'resident.dart';

class Comment {
  final String id;
  final String residentId;
  final String residentName;
  final String content;
  final int timestamp;

  const Comment({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.content,
    required this.timestamp,
  });
}

class Post {
  final String id;
  final String worldId;
  final String residentId;
  final String residentName;
  final String residentAvatar;
  final String content;
  final String? imageUri;
  final int timestamp;
  final ResidentTier tierAtPosting;
  final Map<String, int> reactions;
  final List<Comment> comments;
  final bool isAnnouncement;
  final bool isPinned;

  const Post({
    required this.id,
    required this.worldId,
    required this.residentId,
    required this.residentName,
    required this.residentAvatar,
    required this.content,
    this.imageUri,
    required this.timestamp,
    this.tierAtPosting = ResidentTier.hustlers,
    this.reactions = const {},
    this.comments = const [],
    this.isAnnouncement = false,
    this.isPinned = false,
  });

  Post copyWith({
    String? id,
    String? worldId,
    String? residentId,
    String? residentName,
    String? residentAvatar,
    String? content,
    String? imageUri,
    int? timestamp,
    ResidentTier? tierAtPosting,
    Map<String, int>? reactions,
    List<Comment>? comments,
    bool? isAnnouncement,
    bool? isPinned,
  }) =>
      Post(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        residentId: residentId ?? this.residentId,
        residentName: residentName ?? this.residentName,
        residentAvatar: residentAvatar ?? this.residentAvatar,
        content: content ?? this.content,
        imageUri: imageUri ?? this.imageUri,
        timestamp: timestamp ?? this.timestamp,
        tierAtPosting: tierAtPosting ?? this.tierAtPosting,
        reactions: reactions ?? this.reactions,
        comments: comments ?? this.comments,
        isAnnouncement: isAnnouncement ?? this.isAnnouncement,
        isPinned: isPinned ?? this.isPinned,
      );
}
