import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/typing_persistence_service.dart';

void main() {
  test('activeWindow is within expected typing TTL range', () {
    expect(
      TypingPersistenceService.activeWindow.inSeconds,
      greaterThanOrEqualTo(5),
    );
    expect(
      TypingPersistenceService.activeWindow.inSeconds,
      lessThanOrEqualTo(15),
    );
  });

  test('persistThrottle reduces write churn', () {
    expect(
      TypingPersistenceService.persistThrottle.inSeconds,
      greaterThanOrEqualTo(1),
    );
  });
}
