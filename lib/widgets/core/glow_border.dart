import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

enum GlowTier { apex, elite, hustler }

class GlowBorder extends StatelessWidget {
  final Widget child;
  final GlowTier tier;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  /// When true, only draws the tier accent border — no fill or shadow.
  /// Use with [VSurfacePanel] to avoid stacked glass layers.
  final bool borderOnly;

  const GlowBorder({
    super.key,
    required this.child,
    this.tier = GlowTier.elite,
    this.borderRadius,
    this.padding,
    this.borderOnly = false,
  });

  Color get _borderColor {
    switch (tier) {
      case GlowTier.apex:
        return VColors.tertiary.withValues(alpha: 0.20);
      case GlowTier.elite:
        return VColors.primary.withValues(alpha: 0.20);
      case GlowTier.hustler:
        return VColors.tierHustler.withValues(alpha: 0.20);
    }
  }

  Color get _glowColor {
    switch (tier) {
      case GlowTier.apex:
        return VColors.tertiary.withValues(alpha: 0.3);
      case GlowTier.elite:
        return VColors.primary.withValues(alpha: 0.3);
      case GlowTier.hustler:
        return VColors.tierHustler.withValues(alpha: 0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(VRadius.xl);

    if (borderOnly) {
      return Container(
        padding: padding ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: _borderColor, width: 1),
        ),
        child: child,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: radius,
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(color: _glowColor, blurRadius: 12, spreadRadius: 0),
        ],
      ),
      child: child,
    );
  }
}
