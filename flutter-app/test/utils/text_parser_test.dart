import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/text_parser.dart';

void main() {
  group('TextParser.extractMentions', () {
    test('extracts single mention', () {
      expect(TextParser.extractMentions('Hello @alice'), ['alice']);
    });

    test('extracts multiple mentions', () {
      expect(TextParser.extractMentions('Hello @alice and @bob'), [
        'alice',
        'bob',
      ]);
    });

    test('returns empty list if no mentions', () {
      expect(TextParser.extractMentions('Hello world'), []);
    });

    test('extracts mentions correctly with punctuation', () {
      expect(TextParser.extractMentions('Hello @alice, how are you?'), [
        'alice',
      ]);
    });

    test('handles empty string', () {
      expect(TextParser.extractMentions(''), []);
    });

    test('extracts mention with numbers and underscores', () {
      expect(TextParser.extractMentions('Hello @user_123'), ['user_123']);
    });
  });

  group('TextParser.extractHashtags', () {
    test('extracts single hashtag in lowercase', () {
      expect(TextParser.extractHashtags('Love this #App'), ['app']);
    });

    test('extracts multiple hashtags', () {
      expect(TextParser.extractHashtags('Love this #App and #Flutter'), [
        'app',
        'flutter',
      ]);
    });

    test('returns empty list if no hashtags', () {
      expect(TextParser.extractHashtags('Love this app'), []);
    });

    test('extracts hashtags correctly with punctuation', () {
      expect(TextParser.extractHashtags('Love this #app, it is great!'), [
        'app',
      ]);
    });

    test('handles empty string', () {
      expect(TextParser.extractHashtags(''), []);
    });

    test('extracts hashtag with numbers and underscores', () {
      expect(TextParser.extractHashtags('Love this #app_123'), ['app_123']);
    });
  });

  group('TextParser.containsAllResidents', () {
    test('returns true if @allresidents is present', () {
      expect(TextParser.containsAllResidents('Hello @allresidents'), isTrue);
    });

    test('returns true if @AllResidents is present (case-insensitive)', () {
      expect(TextParser.containsAllResidents('Hello @AllResidents'), isTrue);
    });

    test('returns false if @allresidents is not present', () {
      expect(TextParser.containsAllResidents('Hello @alice'), isFalse);
    });

    test('returns false if text does not contain any mentions', () {
      expect(TextParser.containsAllResidents('Hello world'), isFalse);
    });

    test('handles empty string', () {
      expect(TextParser.containsAllResidents(''), isFalse);
    });

    test('returns false if allresidents is present but not as a mention', () {
      expect(TextParser.containsAllResidents('Hello allresidents'), isFalse);
    });
  });
}
