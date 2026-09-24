import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/date_format.dart';

void main() {
  group('formatTimestamp', () {
    test('returns "just now" for recent timestamps', () {
      expect(
        formatTimestamp(DateTime.now().millisecondsSinceEpoch - 5000),
        'just now',
      );
    });

    test('shows minutes ago', () {
      expect(
        formatTimestamp(DateTime.now().millisecondsSinceEpoch - 120000),
        '2m ago',
      );
    });

    test('shows hours ago', () {
      expect(
        formatTimestamp(DateTime.now().millisecondsSinceEpoch - 7200000),
        '2h ago',
      );
    });

    test('shows days ago', () {
      expect(
        formatTimestamp(DateTime.now().millisecondsSinceEpoch - 172800000),
        '2d ago',
      );
    });
  });
}
