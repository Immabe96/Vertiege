import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/tab_shell_overlay_provider.dart';
import '../../ui/overlays/v_dialog.dart';
import '../../ui/overlays/v_sheet.dart';

/// Modal bottom sheet above tab-shell FAB — delegates to [showVSheet] (DCX-118).
Future<T?> showTabAwareModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
}) async {
  await showVSheet(
    context,
    builder(context),
    maxSize: isScrollControlled ? 0.92 : 0.7,
  );
  return null;
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
    builder: builder,
  ).whenComplete(overlay.release);
}

/// Prestige dialog above tab-shell FAB (e.g. Nexus post edit).
Future<T?> showTabAwareVDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  List<Widget>? actions,
  TextStyle? titleStyle,
  bool scrollContent = false,
  double? maxContentHeight,
}) {
  final container = ProviderScope.containerOf(context);
  final overlay = container.read(tabShellOverlayProvider.notifier);
  overlay.acquire();
  return showVDialog<T>(
    context: context,
    title: title,
    content: content,
    actions: actions,
    titleStyle: titleStyle,
    scrollContent: scrollContent,
    maxContentHeight: maxContentHeight,
  ).whenComplete(overlay.release);
}
