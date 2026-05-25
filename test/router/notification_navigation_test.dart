import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/notification.dart';
import 'package:vertiege/router/notification_navigation.dart';
import 'package:vertiege/router/world_navigation.dart';

void main() {
  group('routeForNotification', () {
    test('like with world and post uses exploreWorldPath', () {
      const n = AppNotification(
        id: 'n1',
        type: NotificationType.like,
        message: 'liked',
        worldId: 'neon-district',
        postId: 'post-1',
        createdAt: 0,
      );
      expect(
        routeForNotification(n),
        exploreWorldPath('neon-district', postId: 'post-1'),
      );
    });

    test('like without world falls back to notifications', () {
      const n = AppNotification(
        id: 'n2',
        type: NotificationType.like,
        message: 'liked',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/notifications');
    });

    test('achievement approved routes to achievements', () {
      const n = AppNotification(
        id: 'n3',
        type: NotificationType.achievementApproved,
        message: 'approved',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/achievements');
    });

    test('allegiance request routes to allies', () {
      const n = AppNotification(
        id: 'n4',
        type: NotificationType.allegianceRequest,
        message: 'request',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/allies');
    });

    test('mention with world uses exploreWorldPath', () {
      const n = AppNotification(
        id: 'n5',
        type: NotificationType.mention,
        message: 'mention',
        worldId: 'world-a',
        createdAt: 0,
      );
      expect(routeForNotification(n), exploreWorldPath('world-a'));
    });
  });

  group('notificationDeepLinkPath', () {
    test('encodes notification id', () {
      expect(
        notificationDeepLinkPath('id/with/slash'),
        '/notifications/id%2Fwith%2Fslash',
      );
    });
  });
}
