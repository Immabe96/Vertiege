import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/string_utils.dart';

void main() {
  group('String Utils', () {
    group('capitalize', () {
      test('capitalizes first letter', () {
        expect(capitalize('hello'), 'Hello');
        expect(capitalize('WORLD'), 'World');
      });

      test('handles empty string', () {
        expect(capitalize(''), '');
      });

      test('handles single character', () {
        expect(capitalize('a'), 'A');
        expect(capitalize('A'), 'A');
      });

      test('handles spaces and special characters', () {
        expect(capitalize(' hello'), ' hello');
        expect(capitalize('!hello'), '!hello');
        expect(capitalize('123hello'), '123hello');
      });

      test('handles already capitalized string', () {
        expect(capitalize('Hello'), 'Hello');
      });

      test('handles mixed case', () {
        expect(capitalize('hElLo'), 'Hello');
      });
    });

    group('truncate', () {
      test('returns full string if shorter than max', () {
        expect(truncate('hi', 10), 'hi');
      });

      test('truncates with ellipsis', () {
        expect(truncate('hello world', 8), 'hello...');
      });

      test('returns full string if exactly max length', () {
        expect(truncate('hello', 5), 'hello');
      });

      test('handles empty string', () {
        expect(truncate('', 5), '');
      });

      test('handles negative max length', () {
        expect(truncate('hello', -1), '');
      });

      test('handles max length < 3', () {
        expect(truncate('hello', 0), '');
        expect(truncate('hello', 1), '.');
        expect(truncate('hello', 2), '..');
        expect(truncate('hello', 3), '...');
      });
    });
  });
}
