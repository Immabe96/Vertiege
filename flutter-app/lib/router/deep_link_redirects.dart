/// Pure helpers for [GoRouter] redirect logic (testable without a widget tree).
library;

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

/// Android intent: `vertiege://residents/UUID` → `/residents/UUID`.
String? redirectResidentsHostDeepLink(Uri uri, String location) {
  if (uri.host != 'residents' || location.startsWith('/residents')) {
    return null;
  }
  final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  if (id.isEmpty) return null;
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '/residents/${Uri.encodeComponent(id)}$query';
}

/// Android intent: `vertiege://invite/ABC123` → `/invite/ABC123`.
String? redirectInviteHostDeepLink(Uri uri, String location) {
  if (uri.host != 'invite' || location.startsWith('/invite')) return null;
  final code = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  if (code.isEmpty) return null;
  return '/invite/${Uri.encodeComponent(code)}';
}

/// `vertiege://post/UUID` → `/post/UUID`.
String? redirectPostHostDeepLink(Uri uri, String location) {
  if (uri.host != 'post' || location.startsWith('/post')) return null;
  final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  if (id.isEmpty) return null;
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '/post/${Uri.encodeComponent(id)}$query';
}

/// `vertiege://world/UUID` → `/explore/UUID`.
String? redirectWorldHostDeepLink(Uri uri, String location) {
  if (uri.host != 'world' || location.startsWith('/explore')) return null;
  final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  if (id.isEmpty) return null;
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '/explore/${Uri.encodeComponent(id)}$query';
}

/// `vertiege://chat/ROOM_ID` → `/chat/ROOM_ID`.
String? redirectChatHostDeepLink(Uri uri, String location) {
  if (uri.host != 'chat' || location.startsWith('/chat')) return null;
  final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  if (id.isEmpty) return null;
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '/chat/${Uri.encodeComponent(id)}$query';
}

/// `vertiege://notifications/UUID` → `/notifications/UUID`.
String? redirectNotificationsHostDeepLink(Uri uri, String location) {
  if (uri.host != 'notifications' ||
      location.startsWith('/notifications')) {
    return null;
  }
  final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
  if (id.isEmpty) return '/notifications';
  final query = uri.hasQuery ? '?${uri.query}' : '';
  return '/notifications/${Uri.encodeComponent(id)}$query';
}
