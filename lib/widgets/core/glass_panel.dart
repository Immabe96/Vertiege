import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final double blur;
  final bool useBlur;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.border,
    this.blur = 12,
    this.useBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    final container = Container(
      padding: padding ?? const EdgeInsets.all(Spacing.lg),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius:
            borderRadius ?? BorderRadius.circular(RadiusTokens.xl),
        border: border ??
            Border.all(color: AppColors.glassBorder),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(RadiusTokens.full),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding ?? const EdgeInsets.all(Spacing.xl),
          decoration: BoxDecoration(
            color: AppColors.glassModalBackground,
            borderRadius: BorderRadius.circular(RadiusTokens.full),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
