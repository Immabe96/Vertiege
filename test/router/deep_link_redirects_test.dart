import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/router/deep_link_redirects.dart';

void main() {
  group('redirectAuthHostDeepLink', () {
    test('auth host callback maps to /auth/callback', () {
      expect(
        redirectAuthHostDeepLink(
          Uri.parse('vertiege://auth/callback'),
          '/callback',
        ),
        '/auth/callback',
      );
    });

    test('already on /auth/callback is unchanged', () {
      expect(
        redirectAuthHostDeepLink(
          Uri.parse('vertiege://auth/callback'),
          '/auth/callback',
        ),
        isNull,
      );
    });
  });

  group('redirectVerifierHostDeepLink', () {
    test('verifier host login maps to /verifier/login', () {
      expect(
        redirectVerifierHostDeepLink(
          Uri.parse('vertiege://verifier/login'),
          '/login',
        ),
        '/verifier/login',
      );
    });
  });

  group('redirectPostHostDeepLink', () {
    test('post host maps to /post/id', () {
      expect(
        redirectPostHostDeepLink(
          Uri.parse('vertiege://post/abc-123'),
          '/abc-123',
        ),
        '/post/abc-123',
      );
    });

    test('skips when already on /post path', () {
      expect(
        redirectPostHostDeepLink(
          Uri.parse('vertiege://post/abc-123'),
          '/post/abc-123',
        ),
        isNull,
      );
    });
  });

  group('redirectWorldHostDeepLink', () {
    test('world host maps to /explore/id', () {
      expect(
        redirectWorldHostDeepLink(
          Uri.parse('vertiege://world/world-1'),
          '/world-1',
        ),
        '/explore/world-1',
      );
    });
  });

  group('redirectChatHostDeepLink', () {
    test('chat host maps to /chat/room', () {
      expect(
        redirectChatHostDeepLink(
          Uri.parse('vertiege://chat/room-1'),
          '/room-1',
        ),
        '/chat/room-1',
      );
    });
  });

  group('redirectNotificationsHostDeepLink', () {
    test('notifications host with id maps to detail route', () {
      expect(
        redirectNotificationsHostDeepLink(
          Uri.parse('vertiege://notifications/n1'),
          '/n1',
        ),
        '/notifications/n1',
      );
    });

    test('notifications host without id maps to inbox', () {
      expect(
        redirectNotificationsHostDeepLink(
          Uri.parse('vertiege://notifications'),
          '',
        ),
        '/notifications',
      );
    });
  });
}
