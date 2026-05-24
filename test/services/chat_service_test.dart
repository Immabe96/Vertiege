import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/chat_service.dart';

void main() {
  group('ChatService.sortedParticipantIds', () {
    test('orders ids lexicographically', () {
      expect(
        ChatService.sortedParticipantIds('b-user', 'a-user'),
        ['a-user', 'b-user'],
      );
    });

    test('is stable for already sorted input', () {
      expect(
        ChatService.sortedParticipantIds('same', 'zebra'),
        ['same', 'zebra'],
      );
    });
  });
}
