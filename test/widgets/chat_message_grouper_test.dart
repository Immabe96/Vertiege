import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/message.dart';
import 'package:vertiege/widgets/chat/chat_message_grouper.dart';

ChannelMessage _msg({
  required String id,
  required String senderId,
  required String senderName,
  required int createdAt,
}) {
  return ChannelMessage(
    id: id,
    channelId: 'ch-1',
    senderId: senderId,
    senderName: senderName,
    content: 'hello',
    createdAt: createdAt,
  );
}

void main() {
  group('buildChatDisplayItems', () {
    test('groups consecutive messages from same author within window', () {
      final items = buildChatDisplayItems([
        _msg(id: '1', senderId: 'a', senderName: 'Ada', createdAt: 1000),
        _msg(id: '2', senderId: 'a', senderName: 'Ada', createdAt: 2000),
        _msg(id: '3', senderId: 'b', senderName: 'Bo', createdAt: 3000),
      ]);

      expect(items.length, 4); // date + first + subsequent + first
      expect(items[1].type, ChatItemType.firstInGroup);
      expect(items[2].type, ChatItemType.subsequent);
      expect(items[3].type, ChatItemType.firstInGroup);
    });

    test('breaks groups after time window', () {
      final items = buildChatDisplayItems([
        _msg(id: '1', senderId: 'a', senderName: 'Ada', createdAt: 0),
        _msg(
          id: '2',
          senderId: 'a',
          senderName: 'Ada',
          createdAt: chatGroupWindow + 1,
        ),
      ]);

      expect(items[1].type, ChatItemType.firstInGroup);
      expect(items[2].type, ChatItemType.firstInGroup);
    });

    test('system messages always start a new group', () {
      final items = buildChatDisplayItems([
        _msg(id: '1', senderId: 'a', senderName: 'Ada', createdAt: 1000),
        _msg(
          id: '2',
          senderId: 'system',
          senderName: 'System',
          createdAt: 1500,
        ),
        _msg(id: '3', senderId: 'a', senderName: 'Ada', createdAt: 2000),
      ]);

      expect(items[2].type, ChatItemType.firstInGroup);
      expect(items[3].type, ChatItemType.firstInGroup);
    });
  });
}
