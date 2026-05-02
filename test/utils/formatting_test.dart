import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_status_worlds/utils/string_utils.dart';
import 'package:virtual_status_worlds/utils/date_format.dart';

void main() {
  group('capitalize', () {
    test('capitalizes first letter', () {
      expect(capitalize('hello'), 'Hello');
      expect(capitalize('WORLD'), 'World');
    });

    test('handles empty string', () {
      expect(capitalize(''), '');
    });
  });

  group('truncate', () {
    test('returns full string if shorter than max', () {
      expect(truncate('hi', 10), 'hi');
    });

    test('truncates with ellipsis', () {
      expect(truncate('hello world', 8), 'hello...');
    });
  });

  group('formatTimestamp', () {
    test('returns "Just now" for recent timestamps', () {
      expect(formatTimestamp(DateTime.now().millisecondsSinceEpoch - 5000), 'Just now');
    });

    test('shows minutes ago', () {
      expect(formatTimestamp(DateTime.now().millisecondsSinceEpoch - 120000), '2m ago');
    });

    test('shows hours ago', () {
      expect(formatTimestamp(DateTime.now().millisecondsSinceEpoch - 7200000), '2h ago');
    });

    test('shows days ago', () {
      expect(formatTimestamp(DateTime.now().millisecondsSinceEpoch - 172800000), '2d ago');
    });
  });
}