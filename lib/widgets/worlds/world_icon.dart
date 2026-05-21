import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../../utils/world_assets.dart';

/// Glass-styled world icon with deterministic icon selection.
///
/// Renders a Material icon inside a frosted-glass container (backdrop blur,
/// semi-transparent background, glass border). The icon is picked
/// deterministically from [WorldAssets.iconForWorld] so every world gets a
/// unique visual identity.
class WorldIcon extends StatelessWidget {
  final String worldId;
  final double size;
  final Color? tintColor;

  const WorldIcon({
    super.key,
    required this.worldId,
    this.size = 64,
    this.tintColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = WorldAssets.iconForWorld(worldId);
    final iconColor = tintColor ?? WorldAssets.accentForWorld(worldId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
        border: Border.all(color: isDark ? VColors.glassBorderDark : VColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.5),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, size: size * 0.5, color: iconColor),
      ),
    );
  }
}
