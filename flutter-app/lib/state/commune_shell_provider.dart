import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../router/app_router.dart';
import '../router/world_route_redirects.dart';

part 'commune_shell_provider.g.dart';

/// Current matched path from [GoRouter] (refreshes on navigation).
@Riverpod(name: 'routerPathProvider', keepAlive: true)
String routerPath(Ref ref) {
  final router = ref.watch(appRouterProvider);
  void listener() {
    ref.invalidateSelf();
  }

  router.routerDelegate.addListener(listener);
  ref.onDispose(() => router.routerDelegate.removeListener(listener));
  return router.routerDelegate.currentConfiguration.uri.path;
}

/// True when bottom tab bar should be hidden (immersive chat / voice).
@Riverpod(name: 'hideBottomNavProvider', keepAlive: true)
bool hideBottomNav(Ref ref) {
  final path = ref.watch(routerPathProvider);
  return communeImmersivePath(path);
}

@visibleForTesting
bool communeImmersivePath(String path) {
  // Primary tab roots always keep the bottom bar visible.
  if (path == '/' ||
      path == '/chat' ||
      path == '/identity' ||
      path == '/explore') {
    return false;
  }

  if (path.startsWith('/campfire/')) return true;

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
