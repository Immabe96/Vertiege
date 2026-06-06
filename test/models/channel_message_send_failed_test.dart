import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/message.dart';

void main() {
  test('sendFailed round-trips through json', () {
    const message = ChannelMessage(
      id: 'm1',
      channelId: 'c1',
      senderId: 'r1',
      senderName: 'Resident',
      content: 'hello',
      createdAt: 1,
      sendFailed: true,
    );

    final restored = ChannelMessage.fromJson(message.toJson());
    expect(restored.sendFailed, isTrue);
    expect(restored.content, 'hello');
  });

  test('sending defaults to false', () {
    const message = ChannelMessage(
      id: 'm1',
      channelId: 'c1',
      senderId: 'r1',
      senderName: 'Resident',
      content: 'hello',
      createdAt: 1,
    );
    expect(message.sending, isFalse);
  });

  test('sending round-trips through json', () {
    const message = ChannelMessage(
      id: 'm1',
      channelId: 'c1',
      senderId: 'r1',
      senderName: 'Resident',
      content: 'hello',
      createdAt: 1,
      sending: true,
    );
    final restored = ChannelMessage.fromJson(message.toJson());
    expect(restored.sending, isTrue);
  });

  test('copyWith flips sending without dropping other state', () {
    const original = ChannelMessage(
      id: 'm1',
      channelId: 'c1',
      senderId: 'r1',
      senderName: 'Resident',
      content: 'hello',
      createdAt: 1,
      sending: true,
    );
    final cleared = original.copyWith(sending: false);
    expect(cleared.sending, isFalse);
    expect(cleared.id, 'm1');
    expect(cleared.content, 'hello');
  });
}

