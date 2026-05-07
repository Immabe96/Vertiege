import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/services/moderation_filter.dart';

void main() {
  group('ModerationFilter.checkContent', () {
    test('returns null for clean content', () {
      expect(ModerationFilter.checkContent('Hello world'), isNull);
      expect(ModerationFilter.checkContent('Normal post content'), isNull);
    });

    test('rejects empty content', () {
      expect(ModerationFilter.checkContent(''), 'Content cannot be empty');
      expect(ModerationFilter.checkContent('   '), 'Content cannot be empty');
    });

    group('profanity detection', () {
      test('flags common profanity', () {
        final result = ModerationFilter.checkContent('this is shit content');
        expect(result, contains('inappropriate language'));
      });

      test('does not flag words containing profanity substrings', () {
        expect(ModerationFilter.checkContent('shitzu'), isNull);
        expect(ModerationFilter.checkContent('class assignment'), isNull);
      });
    });

    group('pattern detection', () {
      test('flags hate speech', () {
        final result = ModerationFilter.checkContent('I hate speech about things');
        expect(result, contains('community guidelines'));
      });
    });

    group('spam detection', () {
      test('flags excessive caps', () {
        final caps = 'A' * 51;
        expect(ModerationFilter.checkContent(caps), contains('spam'));
      });

      test('flags repeated characters', () {
        expect(ModerationFilter.checkContent('hellooooooo'), contains('spam'));
      });

      test('flags repeated words', () {
        expect(ModerationFilter.checkContent('hello hello hello hello world'), contains('spam'));
      });
    });
  });
}
