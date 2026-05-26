/// Pure helpers for resident onboarding / gate redirects (testable without GoRouter).

/// After session exists and resident load finished: route to onboarding or home.
String? resolveResidentOnboardingRedirect({
  required bool hasSession,
  required bool isLoading,
  required bool hasResident,
  required bool gateCompleted,
  required String location,
  required bool isAuthPage,
}) {
  if (!hasSession || isLoading) return null;

  if (!hasResident) {
    return location == '/onboarding' ? null : '/onboarding';
  }

  if (!gateCompleted) {
    return location == '/onboarding' ? null : '/onboarding';
  }

  if (isAuthPage || location == '/onboarding' || location == '/the-gate') {
    return '/';
  }

  return null;
}

/// Unauthenticated users must reach login/signup.
String? resolveUnauthenticatedRedirect({
  required bool hasSession,
  required String location,
  required bool isAuthPage,
}) {
  if (hasSession || isAuthPage) return null;
  return '/login';
}
