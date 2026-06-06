import '../models/notification.dart';

/// Suppresses chat-related push/in-app banners while the user is viewing that surface.
class ChatNotificationScope {
  ChatNotificationScope._();

  static String? activeDmRoomId;
  static String? activeChannelId;
  static String? activeThreadId;

  static void setActiveDmRoom(String? roomId) {
    activeDmRoomId = roomId;
  }

  static void setActiveChannel({
    required String? channelId,
    String? threadId,
  }) {
    activeChannelId = channelId;
    activeThreadId = threadId;
  }

  static void clearChannel() {
    activeChannelId = null;
    activeThreadId = null;
  }

  static bool shouldSuppressDm(String roomId) =>
      activeDmRoomId != null && activeDmRoomId == roomId;

  static bool shouldSuppressNotification(AppNotification notification) {
    if (notification.type == NotificationType.dmMessage) {
      final roomId = notification.roomId;
      if (roomId != null && shouldSuppressDm(roomId)) return true;
    }

    if (notification.type == NotificationType.mention) {
      final channelId = notification.roomId;
      if (channelId != null &&
          activeChannelId != null &&
          activeChannelId == channelId) {
        return true;
      }
    }

    return false;
  }

  static bool shouldSuppressRemote({
    required String type,
    String? roomId,
    String? channelId,
  }) {
    if (type == 'dmMessage' && roomId != null && shouldSuppressDm(roomId)) {
      return true;
    }
    final activeChannel = activeChannelId;
    if (type == 'mention' &&
        channelId != null &&
        activeChannel != null &&
        activeChannel == channelId) {
      return true;
    }
    return false;
  }
}
