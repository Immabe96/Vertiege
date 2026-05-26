import '../models/notification.dart';
import 'world_navigation.dart';

/// Resolves in-app navigation target for a notification (push/go).
String? routeForNotification(AppNotification notification) {
  final worldId = notification.worldId;
  final postId = notification.postId;

  switch (notification.type) {
    case NotificationType.achievementApproved:
    case NotificationType.achievementRejected:
      return '/achievements';
    case NotificationType.allegianceRequest:
      return '/allies';
    case NotificationType.like:
    case NotificationType.comment:
      if (worldId != null && postId != null && postId.isNotEmpty) {
        return exploreWorldPath(worldId, postId: postId);
      }
      if (worldId != null) return exploreWorldPath(worldId);
      return '/notifications';
    case NotificationType.dmMessage:
      final roomId = notification.roomId;
      if (roomId != null && roomId.isNotEmpty) return chatShellPath(roomId);
      return '/chat';
    case NotificationType.mention:
    case NotificationType.worldUnlocked:
      if (worldId != null) return exploreWorldPath(worldId);
      return '/notifications';
    case NotificationType.tierUpgrade:
    case NotificationType.streakReminder:
      return '/identity';
    case NotificationType.welcome:
      return '/explore';
    case NotificationType.modAction:
      return '/settings';
    case NotificationType.ranking:
      return '/season';
    case NotificationType.reactionMilestone:
      if (worldId != null && postId != null && postId.isNotEmpty) {
        return exploreWorldPath(worldId, postId: postId);
      }
      return '/identity';
  }
}

/// Deep-link route when only notification id is known (FCM / legacy).
String notificationDeepLinkPath(String notificationId) =>
    '/notifications/${Uri.encodeComponent(notificationId)}';
