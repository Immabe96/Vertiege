import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../state/tab_shell_overlay_provider.dart';

/// A bottom sheet wrapper using forui's FSheet.
class GlassSheet extends StatelessWidget {
  final Widget child;

  const GlassSheet({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Shows a modal sheet using forui's [showFSheet].
void showAppSheet(
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

@Deprecated('Use showAppSheet')
void showGlassSheet(
  BuildContext context,
  Widget child, {
  double initialSize = 0.7,
  double minSize = 0.25,
  double maxSize = 0.95,
}) =>
    showAppSheet(context, child,
        initialSize: initialSize, minSize: minSize, maxSize: maxSize);
