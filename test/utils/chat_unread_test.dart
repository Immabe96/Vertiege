import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/message.dart';
import 'package:vertiege/utils/chat_unread.dart';

void main() {
  ChannelMessage messageAt(DateTime createdAt) => ChannelMessage(
    id: createdAt.millisecondsSinceEpoch.toString(),
    channelId: 'channel-1',
    senderId: 'resident-1',
    senderName: 'Resident',
    content: 'hello',
    createdAt: createdAt.millisecondsSinceEpoch,
  );

  group('countUnreadMessages', () {
    test('returns zero when no local messages or activity exists', () {
      expect(
        countUnreadMessages(
          loadedMessages: const [],
          lastReadAt: null,
          latestMessageAt: null,
        ),
        0,
      );
    });

    test('counts loaded messages after the last read timestamp', () {
      final readAt = DateTime(2026, 5, 12, 9);
      expect(
        countUnreadMessages(
          loadedMessages: [
            messageAt(readAt.subtract(const Duration(minutes: 3))),
            messageAt(readAt.add(const Duration(minutes: 1))),
            messageAt(readAt.add(const Duration(minutes: 2))),
          ],
          lastReadAt: readAt,
          latestMessageAt: readAt.add(const Duration(minutes: 2)),
        ),
        2,
      );
    });

    test('treats unseen channel activity as a single unread badge', () {
      final readAt = DateTime(2026, 5, 12, 9);
      expect(
        countUnreadMessages(
          loadedMessages: const [],
          lastReadAt: readAt,
          latestMessageAt: readAt.add(const Duration(minutes: 1)),
        ),
        unreadUnknownCount,
      );
    });

    test(
      'does not mark channel unread when latest activity is already read',
      () {
        final readAt = DateTime(2026, 5, 12, 9);
        expect(
          countUnreadMessages(
            loadedMessages: const [],
            lastReadAt: readAt,
            latestMessageAt: readAt.subtract(const Duration(minutes: 1)),
          ),
          0,
        );
      },
    );

    test(
      'marks active never-read channels unread without loading messages',
      () {
        expect(
          countUnreadMessages(
            loadedMessages: const [],
            lastReadAt: null,
            latestMessageAt: DateTime(2026, 5, 12, 9),
          ),
          unreadUnknownCount,
        );
      },
    );

    test('loaded never-read channels use the exact loaded count', () {
      expect(
        countUnreadMessages(
          loadedMessages: [
            messageAt(DateTime(2026, 5, 12, 9)),
            messageAt(DateTime(2026, 5, 12, 10)),
          ],
          lastReadAt: null,
          latestMessageAt: DateTime(2026, 5, 12, 10),
        ),
        2,
      );
    });
  });
}
