import 'resident.dart';

class Comment {
  final String id;
  final String residentId;
  final String residentName;
  final String content;
  final int timestamp;
  final bool isEdited;

  const Comment({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.content,
    required this.timestamp,
    this.isEdited = false,
  });

  Comment copyWith({
    String? id, String? residentId, String? residentName,
    String? content, int? timestamp, bool? isEdited,
  }) => Comment(
    id: id ?? this.id,
    residentId: residentId ?? this.residentId,
    residentName: residentName ?? this.residentName,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
    isEdited: isEdited ?? this.isEdited,
  );
}

class Post {
  final String id;
  final String worldId;
  final String residentId;
  final String residentName;
  final String residentAvatar;
  final String content;
  final String? imageUri;
  final List<String>? imageUris;
  final int timestamp;
  final ResidentTier tierAtPosting;
  final Map<String, int> reactions;
  final List<Comment> comments;
  final bool isAnnouncement;
  final bool isPinned;
  final bool isEdited;
  final String? repostOf;

  const Post({
    required this.id,
    required this.worldId,
    required this.residentId,
    required this.residentName,
    required this.residentAvatar,
    required this.content,
    this.imageUri,
    this.imageUris,
    required this.timestamp,
    this.tierAtPosting = ResidentTier.hustlers,
    this.reactions = const {},
    this.comments = const [],
    this.isAnnouncement = false,
    this.isPinned = false,
    this.isEdited = false,
    this.repostOf,
  });

  /// Resolves the effective list of image URIs, supporting both the legacy
  /// single [imageUri] and the new multi-image [imageUris] field.
  List<String> get allImageUris {
    if (imageUris != null && imageUris!.isNotEmpty) return imageUris!;
    if (imageUri != null && imageUri!.isNotEmpty) return [imageUri!];
    return [];
  }

  bool get hasImages => allImageUris.isNotEmpty;

  Post copyWith({
    String? id,
    String? worldId,
    String? residentId,
    String? residentName,
    String? residentAvatar,
    String? content,
    String? imageUri,
    List<String>? imageUris,
    int? timestamp,
    ResidentTier? tierAtPosting,
    Map<String, int>? reactions,
    List<Comment>? comments,
    bool? isAnnouncement,
    bool? isPinned,
    bool? isEdited,
    String? repostOf,
  }) =>
      Post(
        id: id ?? this.id,
        worldId: worldId ?? this.worldId,
        residentId: residentId ?? this.residentId,
        residentName: residentName ?? this.residentName,
        residentAvatar: residentAvatar ?? this.residentAvatar,
        content: content ?? this.content,
        imageUri: imageUri ?? this.imageUri,
        imageUris: imageUris ?? this.imageUris,
        timestamp: timestamp ?? this.timestamp,
        tierAtPosting: tierAtPosting ?? this.tierAtPosting,
        reactions: reactions ?? this.reactions,
        comments: comments ?? this.comments,
        isAnnouncement: isAnnouncement ?? this.isAnnouncement,
        isPinned: isPinned ?? this.isPinned,
        isEdited: isEdited ?? this.isEdited,
        repostOf: repostOf ?? this.repostOf,
      );
}
