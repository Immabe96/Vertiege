import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../state/tab_shell_overlay_provider.dart';

/// Bottom sheet content wrapper (styling lives in [showVSheet]).
class GlassSheet extends StatelessWidget {
  final Widget child;

  const GlassSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

/// Modal bottom sheet via Forui [showFSheet]; respects tab-shell overlay.
void showVSheet(
  BuildContext context,
  Widget child, {
  double initialSize = 0.7,
  double minSize = 0.25,
  double maxSize = 0.95,
}) {
  final container = ProviderScope.containerOf(context);
  final overlay = container.read(tabShellOverlayProvider.notifier);
  overlay.acquire();
  showFSheet(
    context: context,
    side: FLayout.btt,
    mainAxisMaxRatio: maxSize,
    draggable: true,
    barrierDismissible: true,
    builder: (_) => SingleChildScrollView(child: child),
  ).whenComplete(overlay.release);
}

/// @deprecated Prefer [showVSheet]
void showAppSheet(
  BuildContext context,
  Widget child, {
  double initialSize = 0.7,
  double minSize = 0.25,
  double maxSize = 0.95,
}) =>
    showVSheet(
      context,
      child,
      initialSize: initialSize,
      minSize: minSize,
      maxSize: maxSize,
    );

@Deprecated('Use showVSheet')
void showGlassSheet(
  BuildContext context,
  Widget child, {
  double initialSize = 0.7,
  double minSize = 0.25,
  double maxSize = 0.95,
}) =>
    showVSheet(
      context,
      child,
      initialSize: initialSize,
      minSize: minSize,
      maxSize: maxSize,
    );
