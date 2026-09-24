import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/moderation_filter.dart';

void main() {
  group('ModerationFilter.checkContent', () {
    test('rejects empty', () {
      expect(ModerationFilter.checkContent('   '), isNotNull);
    });

    test('flags obvious profanity', () {
      expect(ModerationFilter.checkContent('what the fuck'), isNotNull);
    });

    test('allows clean text', () {
      expect(
        ModerationFilter.checkContent('Welcome to the Nexus pavilion.'),
        isNull,
      );
    });

    test('flags spammy caps', () {
      expect(
        ModerationFilter.checkContent(
          'THIS IS ALL CAPS SPAM BUY NOW BUY NOW BUY NOW EVERYONE LOOK HERE',
        ),
        isNotNull,
      );
    });
  });
}
