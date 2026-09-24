import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/widgets/chat/v_message_content.dart';

void main() {
  group('VMessageContent', () {
    test('preprocessSpoilers wraps spoiler segments', () {
      expect(
        VMessageContent.preprocessSpoilers('hello ||secret|| world'),
        'hello §SPOILER§secret§/SPOILER§ world',
      );
    });

    test('firstUrl extracts http link', () {
      expect(
        VMessageContent.firstUrl('see https://vertiege.app/docs'),
        'https://vertiege.app/docs',
      );
    });

    test('imageUrlsInContent finds image extensions', () {
      final urls = VMessageContent.imageUrlsInContent(
        'pic https://cdn.example.com/a.png here',
      );
      expect(urls, ['https://cdn.example.com/a.png']);
    });
  });
}
