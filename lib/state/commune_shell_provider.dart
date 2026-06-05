import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../router/world_route_redirects.dart';

/// Current matched path from [GoRouter] (refreshes on navigation).
final routerPathProvider = Provider<String>((ref) {
  final router = ref.watch(appRouterProvider);
  void listener() {
    ref.invalidateSelf();
  }

  router.routerDelegate.addListener(listener);
  ref.onDispose(() => router.routerDelegate.removeListener(listener));
  return router.routerDelegate.currentConfiguration.uri.path;
});

/// True when bottom tab bar should be hidden (immersive chat / voice).
final hideBottomNavProvider = Provider<bool>((ref) {
  final path = ref.watch(routerPathProvider);
  return communeImmersivePath(path);
});

@visibleForTesting
bool communeImmersivePath(String path) {
  if (path.startsWith('/campfire/')) return true;
  if (path.startsWith('/dm/')) return true;

  final chatRoom = RegExp(r'^/chat/[^/]+$');
  if (chatRoom.hasMatch(path)) return true;

  // /explore/:worldId/:channelName (not reserved admin segments)
  final channel = RegExp(r'^/explore/([^/]+)/([^/]+)$');
  final match = channel.firstMatch(path);
  if (match != null) {
    final worldId = match.group(1)!;
    final segment = match.group(2)!;
    if (redirectReservedWorldSubRoute(
          worldId: worldId,
          segment: segment,
          query: '',
        ) ==
        null) {
      return true;
    }
  }
  return false;
}
