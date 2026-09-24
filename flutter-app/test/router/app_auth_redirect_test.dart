import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/router/app_auth_redirect.dart';

void main() {
  group('resolveUnauthenticatedRedirect', () {
    test('sends guests to login', () {
      expect(
        resolveUnauthenticatedRedirect(
          hasSession: false,
          location: '/explore',
          isAuthPage: false,
        ),
        '/login',
      );
    });

    test('allows auth pages', () {
      expect(
        resolveUnauthenticatedRedirect(
          hasSession: false,
          location: '/login',
          isAuthPage: true,
        ),
        isNull,
      );
    });
  });

  group('resolveResidentOnboardingRedirect', () {
    test('incomplete gate uses onboarding not the-gate', () {
      expect(
        resolveResidentOnboardingRedirect(
          hasSession: true,
          isLoading: false,
          hasResident: true,
          gateCompleted: false,
          location: '/the-gate',
          isAuthPage: false,
        ),
        '/onboarding',
      );
    });

    test('completed gate clears auth and onboarding routes', () {
      expect(
        resolveResidentOnboardingRedirect(
          hasSession: true,
          isLoading: false,
          hasResident: true,
          gateCompleted: true,
          location: '/onboarding',
          isAuthPage: false,
        ),
        '/',
      );
    });

    test('no resident forces onboarding', () {
      expect(
        resolveResidentOnboardingRedirect(
          hasSession: true,
          isLoading: false,
          hasResident: false,
          gateCompleted: false,
          location: '/',
          isAuthPage: false,
        ),
        '/onboarding',
      );
    });

    test('loading does not redirect', () {
      expect(
        resolveResidentOnboardingRedirect(
          hasSession: true,
          isLoading: true,
          hasResident: false,
          gateCompleted: false,
          location: '/',
          isAuthPage: false,
        ),
        isNull,
      );
    });
  });
}
