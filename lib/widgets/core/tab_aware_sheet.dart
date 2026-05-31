import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/tab_shell_overlay_provider.dart';

/// Modal bottom sheet above tab-shell FAB and other fixed chrome.
Future<T?> showTabAwareModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  Color? backgroundColor,
  bool useSafeArea = false,
}) {
  final container = ProviderScope.containerOf(context);
  final overlay = container.read(tabShellOverlayProvider.notifier);
  overlay.acquire();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: true,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    builder: (context) => Material(
      color: Colors.transparent,
      child: builder(context),
    ),
  ).whenComplete(overlay.release);
}

/// Alert dialog above tab-shell FAB (e.g. Nexus post edit).
Future<T?> showTabAwareDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final container = ProviderScope.containerOf(context);
  final overlay = container.read(tabShellOverlayProvider.notifier);
  overlay.acquire();
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => Material(
      type: MaterialType.transparency,
      child: builder(context),
    ),
  ).whenComplete(overlay.release);
}
