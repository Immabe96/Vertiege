import 'dart:ui';

import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Container card with surface-aware background.
///
/// Solid surfaces by default — no blur in chat shell (DCX-040).
/// [useBlur] is opt-in for modals and image viewers only.
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
      padding: padding ?? const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? VCommuneColors.surfaceSecondary
            : VCommuneColors.surfaceSecondaryLight,
        borderRadius: borderRadius ?? BorderRadius.circular(VRadius.communeCard),
        border: border ??
            Border.all(
              color: VCommuneColors.dividerOf(
                isDark ? Brightness.dark : Brightness.light,
              ),
              width: 1,
            ),
        boxShadow: shadows ?? const [],
      ),
      child: child,
    );

    if (!useBlur) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(VRadius.communeCard),
        child: container,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(VRadius.communeCard),
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
      borderRadius: BorderRadius.circular(VRadius.communeCard),
      child: Container(
        padding: padding ?? const EdgeInsets.all(VSpacing.lg),
        decoration: BoxDecoration(
          color: isDark
              ? VCommuneColors.surfaceFloating
              : VCommuneColors.surfaceFloatingLight,
          borderRadius: BorderRadius.circular(VRadius.communeCard),
          border: Border.all(
            color: VCommuneColors.dividerOf(
              isDark ? Brightness.dark : Brightness.light,
            ),
            width: 1,
          ),
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
