import 'package:flutter/material.dart';
import '../../theme/colors.dart';
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
        return AppColors.tertiary.withValues(alpha: 0.20);
      case GlowTier.elite:
        return AppColors.primary.withValues(alpha: 0.20);
      case GlowTier.hustler:
        return AppColors.hustler.withValues(alpha: 0.20);
    }
  }

  Color get _glowColor {
    switch (tier) {
      case GlowTier.apex:
        return AppColors.tertiary.withValues(alpha: AppColors.glowGoldAlpha);
      case GlowTier.elite:
        return AppColors.primary.withValues(alpha: AppColors.glowVioletAlpha);
      case GlowTier.hustler:
        return AppColors.hustler.withValues(alpha: AppColors.glowOrangeAlpha);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: borderRadius ?? BorderRadius.circular(RadiusTokens.xl),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: _glowColor,
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
