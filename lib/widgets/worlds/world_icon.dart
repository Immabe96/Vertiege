
import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_assets.dart';

/// Glass-styled world icon with deterministic icon selection.
///
/// Renders a Material icon inside a frosted-glass container (backdrop blur,
/// semi-transparent background, glass border). The icon is picked
/// deterministically from [WorldAssets.iconForWorld] so every world gets a
/// unique visual identity.
class WorldIcon extends StatelessWidget {
  /// World id or slug used to resolve raster art ([World.assetKey] for presets).
  final String worldId;
  final double size;
  final Color? tintColor;
  /// When false, shows only the raster/Material emblem (no glass box or glow).
  final bool useGlassContainer;
  /// Commune rail/header: circular clip without glass chrome (DCX-078).
  final bool circular;

  const WorldIcon({
    super.key,
    required this.worldId,
    this.size = VWorldIconSize.header,
    this.tintColor,
    this.useGlassContainer = true,
    this.circular = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = tintColor ?? WorldAssets.accentForWorld(worldId);
    final rasterPath = WorldAssets.iconImageForWorld(worldId);
    final emblemSize = useGlassContainer ? size * 0.72 : size * 0.88;

    final emblem = rasterPath != null
        ? Image.asset(
            rasterPath,
            width: emblemSize,
            height: emblemSize,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _materialIcon(iconColor),
          )
        : _materialIcon(iconColor);

    if (!useGlassContainer) {
      final child = SizedBox(width: size, height: size, child: Center(child: emblem));
      if (circular) {
        return ClipOval(child: child);
      }
      return child;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: VColors.glassBackgroundDark,
        borderRadius: circular ? null : BorderRadius.circular(VRadius.xl),
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        border: Border.all(color: VColors.glassBorderDark),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(child: emblem),
    );
  }

  Widget _materialIcon(Color iconColor) {
    return Icon(
      WorldAssets.iconForWorld(worldId),
      size: size * 0.5,
      color: iconColor,
    );
  }
}
