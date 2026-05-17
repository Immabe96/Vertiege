import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

/// A glass-morphism bottom sheet with backdrop blur overlay.
///
/// Wraps a [DraggableScrollableSheet] inside a [showModalBottomSheet] with
/// transparent background, blur, and a gold drag handle.
class GlassSheet extends StatelessWidget {
  final Widget child;
  final double initialSize;
  final double minSize;
  final double maxSize;

  const GlassSheet({
    super.key,
    required this.child,
    this.initialSize = 0.7,
    this.minSize = 0.25,
    this.maxSize = 0.95,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(RadiusTokens.cardFeatured),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(RadiusTokens.cardFeatured),
            ),
            border: Border.all(color: isDark ? VColors.glassBorderDark : VColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Gold drag handle ──
              Center(
                child: Container(
                  margin: const EdgeInsets.only(
                    top: Spacing.md,
                    bottom: Spacing.sm,
                  ),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VColors.tertiary,
                    borderRadius: BorderRadius.circular(RadiusTokens.sm),
                  ),
                ),
              ),
              // ── Content ──
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a [GlassSheet] modal bottom sheet.
///
/// The sheet fills the screen with a transparent background, backdrop blur,
/// and a gold drag handle. Swipe down to dismiss, swipe up to expand.
void showGlassSheet(
  BuildContext context,
  Widget child, {
  double initialSize = 0.7,
  double minSize = 0.25,
  double maxSize = 0.95,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: VColors.scrim,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      builder: (_, scrollController) {
        return GlassSheet(
          initialSize: initialSize,
          minSize: minSize,
          maxSize: maxSize,
          child: SingleChildScrollView(
            controller: scrollController,
            child: child,
          ),
        );
      },
    ),
  );
}
