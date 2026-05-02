enum NotificationType { like, comment, worldUnlocked, tierUpgrade, welcome }

class AppNotification {
  final String id;
  final NotificationType type;
  final String message;
  final String? worldId;
  final String? postId;
  final bool read;
  final int createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.worldId,
    this.postId,
    this.read = false,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? message,
    String? worldId,
    String? postId,
    bool? read,
    int? createdAt,
  }) =>
      AppNotification(
        id: id ?? this.id,
        type: type ?? this.type,
        message: message ?? this.message,
        worldId: worldId ?? this.worldId,
        postId: postId ?? this.postId,
        read: read ?? this.read,
        createdAt: createdAt ?? this.createdAt,
      );

  static NotificationType typeFromString(String value) {
    return switch (value) {
      'like' => NotificationType.like,
      'comment' => NotificationType.comment,
      'world_unlocked' => NotificationType.worldUnlocked,
      'tier_upgrade' => NotificationType.tierUpgrade,
      'welcome' => NotificationType.welcome,
      _ => NotificationType.like,
    };
  }
}
