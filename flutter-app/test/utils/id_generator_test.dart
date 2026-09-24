import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/id_generator.dart';

void main() {
  group('generateId', () {
    test('returns a non-empty string', () {
      final id = generateId();
      expect(id, isNotEmpty);
      expect(id, isA<String>());
    });

    test('generates valid UUID v4 format', () {
      final id = generateId();

      // UUID v4 regex pattern: 8-4-4-4-12 hex digits with a '4' as the 13th digit
      // and '8', '9', 'a', or 'b' as the 17th digit
      final uuidV4Regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );

      expect(
        uuidV4Regex.hasMatch(id),
        isTrue,
        reason: 'ID $id does not match UUID v4 format',
      );
    });

    test('generates unique IDs', () {
      // Generate multiple IDs and ensure they are all distinct
      final count = 1000;
      final ids = <String>{};

      for (var i = 0; i < count; i++) {
        final id = generateId();
        // If the ID is already in the set, add() returns false
        expect(ids.add(id), isTrue, reason: 'Collision detected with ID: $id');
      }

      expect(ids.length, equals(count));
    });
  });
}
