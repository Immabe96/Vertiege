import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/notification.dart';
import 'package:vertiege/services/chat_notification_scope.dart';

void main() {
  tearDown(() {
    ChatNotificationScope.setActiveDmRoom(null);
    ChatNotificationScope.clearChannel();
  });

  test('suppresses DM notifications for the active room', () {
    ChatNotificationScope.setActiveDmRoom('room-1');
    expect(ChatNotificationScope.shouldSuppressDm('room-1'), isTrue);
    expect(ChatNotificationScope.shouldSuppressDm('room-2'), isFalse);
  });

  test('suppresses mention notifications for the active channel', () {
    ChatNotificationScope.setActiveChannel(channelId: 'chan-1');
    final notification = AppNotification(
      id: 'n1',
      type: NotificationType.mention,
      message: 'Ping',
      roomId: 'chan-1',
      createdAt: 0,
    );
    expect(
      ChatNotificationScope.shouldSuppressNotification(notification),
      isTrue,
    );
  });
}
