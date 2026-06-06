import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/chat_unread.dart';

void main() {
  test('worldRailUnreadCount suppresses muted worlds', () {
    expect(worldRailUnreadCount(rawCount: 5, muted: true), 0);
    expect(worldRailUnreadCount(rawCount: 5, muted: false), 5);
    expect(worldRailUnreadCount(rawCount: 0, muted: false), 0);
  });
}
