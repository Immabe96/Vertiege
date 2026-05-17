import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final double blur;
  final bool useBlur;
  final List<BoxShadow>? shadows;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.border,
    this.blur = 12,
    this.useBlur = true,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final container = Container(
      padding: padding ?? const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(RadiusTokens.xl),
        border: border ?? Border.all(color: isDark ? VColors.glassBorderDark : VColors.glassBorder, width: 0.5),
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: (isDark ? VColors.onSurfaceDark : VColors.onSurface).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
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

class GlassModal extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const GlassModal({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(RadiusTokens.xl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
            borderRadius: BorderRadius.circular(RadiusTokens.xl),
            border: Border.all(color: isDark ? VColors.glassBorderDark : VColors.glassBorder, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: (isDark ? VColors.onSurfaceDark : VColors.onSurface).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
