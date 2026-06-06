import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/channel.dart';
import 'package:vertiege/utils/chat_channel_sort.dart';

WorldChannel _channel({
  required String id,
  required int position,
  ChannelType type = ChannelType.text,
}) => WorldChannel(
  id: id,
  worldId: 'world-1',
  name: id,
  channelType: type,
  position: position,
  isDefault: false,
  createdAt: 0,
  foundationMarkdown: '',
  foundationVersion: '',
);

void main() {
  group('sortChatChannelsWithUnreadFirst', () {
    test('floats unread channels to the top', () {
      final a = _channel(id: 'a', position: 1);
      final b = _channel(id: 'b', position: 2);
      final c = _channel(id: 'c', position: 3);
      final sorted = sortChatChannelsWithUnreadFirst(
        channels: [a, b, c],
        unreadByChannelId: const {'b': 1},
      );
      expect(sorted.map((c) => c.id).toList(), ['b', 'a', 'c']);
    });

    test('preserves position order among unread channels', () {
      final a = _channel(id: 'a', position: 1);
      final b = _channel(id: 'b', position: 2);
      final c = _channel(id: 'c', position: 3);
      final sorted = sortChatChannelsWithUnreadFirst(
        channels: [a, b, c],
        unreadByChannelId: const {'c': 2, 'a': 1},
      );
      expect(sorted.map((c) => c.id).toList(), ['a', 'c', 'b']);
    });

    test('preserves position order among read channels', () {
      final a = _channel(id: 'a', position: 1);
      final b = _channel(id: 'b', position: 2);
      final c = _channel(id: 'c', position: 3);
      final sorted = sortChatChannelsWithUnreadFirst(
        channels: [a, b, c],
        unreadByChannelId: const {},
      );
      expect(sorted.map((c) => c.id).toList(), ['a', 'b', 'c']);
    });

    test('treats zero counts as read', () {
      final a = _channel(id: 'a', position: 1);
      final b = _channel(id: 'b', position: 2);
      final sorted = sortChatChannelsWithUnreadFirst(
        channels: [a, b],
        unreadByChannelId: const {'a': 0, 'b': 1},
      );
      expect(sorted.map((c) => c.id).toList(), ['b', 'a']);
    });

    test('does not mutate the input list', () {
      final a = _channel(id: 'a', position: 1);
      final b = _channel(id: 'b', position: 2);
      final input = [a, b];
      sortChatChannelsWithUnreadFirst(
        channels: input,
        unreadByChannelId: const {'b': 1},
      );
      expect(input.map((c) => c.id).toList(), ['a', 'b']);
    });

    test('returns empty list for empty input', () {
      expect(
        sortChatChannelsWithUnreadFirst(
          channels: const [],
          unreadByChannelId: const {},
        ),
        isEmpty,
      );
    });
  });
}
