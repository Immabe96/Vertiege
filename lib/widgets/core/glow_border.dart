import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

enum GlowTier { apex, elite, hustler }

class GlowBorder extends StatelessWidget {
  final Widget child;
  final GlowTier tier;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlowBorder({
    super.key,
    required this.child,
    this.tier = GlowTier.elite,
    this.borderRadius,
    this.padding,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(RadiusTokens.xl),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(color: _glowColor, blurRadius: 15, spreadRadius: 0),
        ],
      ),
      child: child,
    );
  }
}
