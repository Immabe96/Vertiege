import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Surface elevation via lightness, not drop shadow (DCX-031).
enum VSurfaceElevation { low, medium, high, floating }

/// Forui-style card shell using commune surface ladder — no shadows.
class VSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VSurfaceElevation elevation;
  final Brightness? brightness;

  const VSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VSpacing.md),
    this.elevation = VSurfaceElevation.medium,
    this.brightness,
  });

  Color _surfaceColor(Brightness b) => switch (elevation) {
    VSurfaceElevation.low =>
      b == Brightness.dark
          ? VCommuneColors.surfacePrimary
          : VCommuneColors.surfacePrimaryLight,
    VSurfaceElevation.medium =>
      b == Brightness.dark
          ? VCommuneColors.surfaceSecondary
          : VCommuneColors.surfaceSecondaryLight,
    VSurfaceElevation.high =>
      b == Brightness.dark
          ? VCommuneColors.surfaceSecondaryAlt
          : VCommuneColors.surfaceSecondaryAltLight,
    VSurfaceElevation.floating =>
      b == Brightness.dark
          ? VCommuneColors.surfaceFloating
          : VCommuneColors.surfaceFloatingLight,
  };

  @override
  Widget build(BuildContext context) {
    final b = brightness ?? Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        color: _surfaceColor(b),
        borderRadius: BorderRadius.circular(VRadius.communeCard),
        border: Border.all(color: VCommuneColors.dividerOf(b)),
      ),
      padding: padding,
      child: child,
    );
  }
}
