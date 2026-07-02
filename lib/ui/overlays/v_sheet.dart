import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../state/tab_shell_overlay_provider.dart';
import '../../theme/v_tokens.dart';

/// Bottom sheet content wrapper (styling lives in [showVSheet]).
class GlassSheet extends StatelessWidget {
  final Widget child;

  const GlassSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

/// Opaque surface for modal sheets — Forui [showFSheet] does not paint a background.
Widget vSheetSurface(
  BuildContext context,
  Widget child, {
  FLayout side = FLayout.btt,
}) {
  final colors = context.theme.colors;
  final borderRadius = switch (side) {
    FLayout.btt => const BorderRadius.vertical(
      top: Radius.circular(VRadius.xl),
    ),
    FLayout.ttb => const BorderRadius.vertical(
      bottom: Radius.circular(VRadius.xl),
    ),
    FLayout.ltr => const BorderRadius.horizontal(
      right: Radius.circular(VRadius.xl),
    ),
    FLayout.rtl => const BorderRadius.horizontal(
      left: Radius.circular(VRadius.xl),
    ),
  };

  return Material(
    color: colors.card,
    elevation: 12,
    shadowColor: Colors.black.withValues(alpha: 0.4),
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadius,
      side: BorderSide(color: colors.border),
    ),
    child: child,
  );
}

/// Modal bottom sheet via Forui [showFSheet]; respects tab-shell overlay.
Future<void> showVSheet(
  BuildContext context,
  Widget child, {
  double initialSize = 0.7,
  double minSize = 0.25,
  double maxSize = 0.95,
  FLayout side = FLayout.btt,
}) {
  final container = ProviderScope.containerOf(context);
  final overlay = container.read(tabShellOverlayProvider.notifier);
  overlay.acquire();
  return showFSheet(
    context: context,
    side: side,
    mainAxisMaxRatio: maxSize,
    builder: (sheetContext) => vSheetSurface(
      sheetContext,
      SingleChildScrollView(child: child),
      side: side,
    ),
  ).whenComplete(overlay.release);
}

/// Side panel sheet for tablet / wide layouts (DCX-117).
void showVSideSheet(
  BuildContext context,
  Widget child, {
  double maxSize = 0.45,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final useSide = width >= 720;

  if (!useSide) {
    showVSheet(context, child, maxSize: 0.92);
    return;
  }

  final container = ProviderScope.containerOf(context);
  final overlay = container.read(tabShellOverlayProvider.notifier);
  overlay.acquire();
  showFSheet(
    context: context,
    side: FLayout.ltr,
    mainAxisMaxRatio: maxSize,
    builder: (sheetContext) => vSheetSurface(
      sheetContext,
      SingleChildScrollView(child: child),
      side: FLayout.ltr,
    ),
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
