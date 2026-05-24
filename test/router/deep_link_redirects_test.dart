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
}
