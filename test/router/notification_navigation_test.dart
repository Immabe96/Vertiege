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

    test('comment with world and post uses exploreWorldPath', () {
      const n = AppNotification(
        id: 'n-comment',
        type: NotificationType.comment,
        message: 'commented',
        worldId: 'world-a',
        postId: 'post-9',
        createdAt: 0,
      );
      expect(
        routeForNotification(n),
        exploreWorldPath('world-a', postId: 'post-9'),
      );
    });

    test('achievement approved routes to identity', () {
      const n = AppNotification(
        id: 'n3',
        type: NotificationType.achievementApproved,
        message: 'approved',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/identity');
    });

    test('identity verified routes to identity', () {
      const n = AppNotification(
        id: 'n3a',
        type: NotificationType.identityVerified,
        message: 'verified',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/identity');
    });

    test('identity rejected routes to identity', () {
      const n = AppNotification(
        id: 'n3c',
        type: NotificationType.identityRejected,
        message: 'rejected',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/identity');
    });

    test('achievement rejected routes to achievements', () {
      const n = AppNotification(
        id: 'n3b',
        type: NotificationType.achievementRejected,
        message: 'rejected',
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

    test('dm message routes to chat shell room', () {
      const n = AppNotification(
        id: 'n-dm',
        type: NotificationType.dmMessage,
        message: 'Alice: hi',
        roomId: 'room-1',
        createdAt: 0,
      );
      expect(routeForNotification(n), chatShellPath('room-1'));
    });

    test('dm message without roomId routes to /chat not /chats', () {
      const n = AppNotification(
        id: 'n-dm-list',
        type: NotificationType.dmMessage,
        message: 'Alice: hi',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/chat');
      expect(routeForNotification(n), isNot('/chats'));
    });

    test('dm message with messageId appends scroll-to query', () {
      const n = AppNotification(
        id: 'n-dm-msg',
        type: NotificationType.dmMessage,
        message: 'Alice: hi',
        roomId: 'room-1',
        messageId: 'msg-99',
        createdAt: 0,
      );
      expect(
        routeForNotification(n),
        chatShellPath('room-1', messageId: 'msg-99'),
      );
    });

    test('mention with world and channel opens channel screen', () {
      const n = AppNotification(
        id: 'n5',
        type: NotificationType.mention,
        message: 'mention',
        worldId: 'world-a',
        channelId: 'ch-1',
        createdAt: 0,
      );
      expect(
        routeForNotification(n),
        worldChannelPathFromParts(
          'world-a',
          channelId: 'ch-1',
          channelName: 'mentions',
        ),
      );
    });

    test('mention with world only uses exploreWorldPath', () {
      const n = AppNotification(
        id: 'n5a',
        type: NotificationType.mention,
        message: 'mention',
        worldId: 'world-a',
        createdAt: 0,
      );
      expect(routeForNotification(n), exploreWorldPath('world-a'));
    });

    test('mention without world falls back to notifications', () {
      const n = AppNotification(
        id: 'n5b',
        type: NotificationType.mention,
        message: 'mention',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/notifications');
    });

    test('worldUnlocked with world uses exploreWorldPath', () {
      const n = AppNotification(
        id: 'n6',
        type: NotificationType.worldUnlocked,
        message: 'unlocked',
        worldId: 'world-b',
        createdAt: 0,
      );
      expect(routeForNotification(n), exploreWorldPath('world-b'));
    });

    test('tierUpgrade routes to identity', () {
      const n = AppNotification(
        id: 'n7',
        type: NotificationType.tierUpgrade,
        message: 'tier up',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/identity');
    });

    test('streakReminder routes to identity', () {
      const n = AppNotification(
        id: 'n8',
        type: NotificationType.streakReminder,
        message: 'streak',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/identity');
    });

    test('welcome routes to explore', () {
      const n = AppNotification(
        id: 'n9',
        type: NotificationType.welcome,
        message: 'welcome',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/explore');
    });

    test('modAction routes to settings', () {
      const n = AppNotification(
        id: 'n10',
        type: NotificationType.modAction,
        message: 'mod',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/settings');
    });

    test('ranking routes to season', () {
      const n = AppNotification(
        id: 'n11',
        type: NotificationType.ranking,
        message: 'rank',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/season');
    });

    test('reactionMilestone with post routes to world feed', () {
      const n = AppNotification(
        id: 'n12',
        type: NotificationType.reactionMilestone,
        message: 'milestone',
        worldId: 'world-c',
        postId: 'post-2',
        createdAt: 0,
      );
      expect(
        routeForNotification(n),
        exploreWorldPath('world-c', postId: 'post-2'),
      );
    });

    test('reactionMilestone without post routes to identity', () {
      const n = AppNotification(
        id: 'n13',
        type: NotificationType.reactionMilestone,
        message: 'milestone',
        createdAt: 0,
      );
      expect(routeForNotification(n), '/identity');
    });

    test('job application accepted routes to world jobs', () {
      const n = AppNotification(
        id: 'n-job-ok',
        type: NotificationType.jobApplicationAccepted,
        message: 'accepted',
        worldId: 'neon-district',
        createdAt: 0,
      );
      expect(routeForNotification(n), worldJobsPath('neon-district'));
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
