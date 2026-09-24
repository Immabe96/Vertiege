class AnnouncementPriority {
  static const String low = 'low';
  static const String normal = 'normal';
  static const String high = 'high';
  static const String urgent = 'urgent';
}

class WorldAnnouncement {
  final String id;
  final String worldId;
  final String authorId;
  final String authorName;
  final String title;
  final String content;
  final String? imageUrl;
  final String priority;
  final bool isPinned;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorldAnnouncement({
    required this.id,
    required this.worldId,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.content,
    this.imageUrl,
    this.priority = AnnouncementPriority.normal,
    this.isPinned = false,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isActive => !isExpired;

  Map<String, dynamic> toJson() => {
    'id': id,
    'world_id': worldId,
    'author_id': authorId,
    'author_name': authorName,
    'title': title,
    'content': content,
    if (imageUrl != null) 'image_url': imageUrl,
    'priority': priority,
    'is_pinned': isPinned,
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory WorldAnnouncement.fromJson(Map<String, dynamic> json) => WorldAnnouncement(
    id: json['id'] ?? '',
    worldId: json['world_id'] ?? '',
    authorId: json['author_id'] ?? '',
    authorName: json['author_name'] ?? '',
    title: json['title'] ?? '',
    content: json['content'] ?? '',
    imageUrl: json['image_url'],
    priority: json['priority'] ?? AnnouncementPriority.normal,
    isPinned: json['is_pinned'] == true,
    expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
    createdAt: _parseDate(json['created_at']),
    updatedAt: _parseDate(json['updated_at']),
  );

  static WorldAnnouncement fromSupabase(Map<String, dynamic> data) => WorldAnnouncement(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    authorId: data['author_id'] ?? '',
    authorName: data['author_name'] ?? '',
    title: data['title'] ?? '',
    content: data['content'] ?? '',
    imageUrl: data['image_url'],
    priority: data['priority'] ?? AnnouncementPriority.normal,
    isPinned: data['is_pinned'] == true,
    expiresAt: data['expires_at'] != null ? DateTime.tryParse(data['expires_at']) : null,
    createdAt: _parseDate(data['created_at']),
    updatedAt: _parseDate(data['updated_at']),
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}
