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
}
