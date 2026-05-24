/// Pure helpers for [GoRouter] redirect logic (testable without a widget tree).

/// Android intent: `vertiege://auth/callback` → host `auth`, path `/callback`.
String? redirectAuthHostDeepLink(Uri uri, String location) {
  if (uri.host != 'auth' || location == '/auth/callback') return null;
  if (location == '/callback' || location.isEmpty || location == '/') {
    return '/auth/callback';
  }
  if (!location.startsWith('/auth')) {
    return '/auth$location';
  }
  return null;
}

/// Android intent: `vertiege://verifier/login` → host `verifier`.
String? redirectVerifierHostDeepLink(Uri uri, String location) {
  if (uri.host != 'verifier' || location.startsWith('/verifier')) return null;
  if (location == '/login' || location.isEmpty || location == '/') {
    return '/verifier/login';
  }
  return '/verifier$location';
}
