import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/channel_typing_label.dart';

void main() {
  test('returns null when only current user is typing', () {
    expect(
      channelTypingLabel({'u1'}, currentUserId: 'u1'),
      isNull,
    );
  });

  test('returns single typer label', () {
    expect(
      channelTypingLabel({'u2'}, currentUserId: 'u1'),
      'Someone is typing…',
    );
  });

  test('returns plural residents label', () {
    expect(
      channelTypingLabel({'u2', 'u3'}, currentUserId: 'u1'),
      '2 residents typing…',
    );
  });
}
