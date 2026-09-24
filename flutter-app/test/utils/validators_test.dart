import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/validators.dart';

void main() {
  group('isUuid', () {
    test('returns true for a valid lowercase UUID', () {
      expect(isUuid('550e8400-e29b-41d4-a716-446655440000'), isTrue);
      expect(isUuid('123e4567-e89b-12d3-a456-426614174000'), isTrue);
    });

    test('returns false for an empty string', () {
      expect(isUuid(''), isFalse);
    });

    test('returns true for a UUID with uppercase characters', () {
      expect(isUuid('550E8400-E29B-41D4-A716-446655440000'), isTrue);
    });

    test('returns false for a string with invalid length', () {
      expect(isUuid('550e8400-e29b-41d4-a716-44665544000'), isFalse); // Too short
      expect(isUuid('550e8400-e29b-41d4-a716-4466554400000'), isFalse); // Too long
    });

    test('returns false for a UUID with missing hyphens', () {
      expect(isUuid('550e8400e29b41d4a716446655440000'), isFalse);
    });

    test('returns false for a UUID with invalid characters', () {
      expect(isUuid('550e8400-e29b-41d4-a716-44665544000g'), isFalse); // 'g' is not hex
      expect(isUuid('x50e8400-e29b-41d4-a716-446655440000'), isFalse); // 'x' is not hex
    });

    test('returns false for a UUID with extra characters at start or end', () {
      expect(isUuid(' 550e8400-e29b-41d4-a716-446655440000'), isFalse);
      expect(isUuid('550e8400-e29b-41d4-a716-446655440000 '), isFalse);
    });
  });
}
