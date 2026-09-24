import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/text_parser.dart';

void main() {
  group('TextParser mentions', () {
    test('extractResidentMentionHandles excludes broadcast keywords', () {
      expect(
        TextParser.extractResidentMentionHandles(
          'hey @Ada and @AllResidents @everyone',
        ),
        ['Ada'],
      );
    });

    test('mentionHandleForName strips non-alphanumeric characters', () {
      expect(
        TextParser.mentionHandleForName('Ada Lovelace'),
        'AdaLovelace',
      );
    });

    test('messageMentionsHandle matches case-insensitively', () {
      expect(
        TextParser.messageMentionsHandle('ping @adaLovelace', 'AdaLovelace'),
        isTrue,
      );
      expect(
        TextParser.messageMentionsHandle('ping @bob', 'AdaLovelace'),
        isFalse,
      );
    });

    test('containsAllResidents matches broadcast aliases', () {
      expect(TextParser.containsAllResidents('@everyone stand up'), isTrue);
      expect(TextParser.containsAllResidents('@Ada hello'), isFalse);
    });
  });
}
