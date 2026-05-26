/// Suppresses DM push banners while the user is viewing that chat room.
class ChatNotificationScope {
  ChatNotificationScope._();

  static String? activeDmRoomId;

  static void setActiveDmRoom(String? roomId) {
    activeDmRoomId = roomId;
  }

  static bool shouldSuppressDm(String roomId) =>
      activeDmRoomId != null && activeDmRoomId == roomId;
}
