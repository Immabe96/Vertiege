import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

/// Container card with surface-aware background.
///
/// Replaces legacy glassmorphism with clean surface container colors.
/// BackdropFilter is opt-in for documented exceptions only
/// (image viewers, export/share visuals, image scrims).
class VSurfacePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final double blur;
  final bool useBlur;
  final List<BoxShadow>? shadows;

  const VSurfacePanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.border,
    this.blur = 12,
    this.useBlur = false,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final container = Container(
      padding: padding ?? const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: borderRadius ?? BorderRadius.circular(RadiusTokens.xl),
        border: border ?? Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
          width: 0.5,
        ),
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: (isDark ? VColors.onSurfaceDark : VColors.onSurface).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: child,
    );

    if (!useBlur) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(RadiusTokens.xl),
        child: container,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(RadiusTokens.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: container,
      ),
    );
  }
}

class VSurfaceModal extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const VSurfaceModal({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(RadiusTokens.xl),
      child: Container(
        padding: padding ?? const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
          border: Border.all(
            color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? VColors.onSurfaceDark : VColors.onSurface).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

@Deprecated('Use VSurfacePanel')
typedef GlassPanel = VSurfacePanel;

@Deprecated('Use VSurfaceModal')
typedef GlassModal = VSurfaceModal;
