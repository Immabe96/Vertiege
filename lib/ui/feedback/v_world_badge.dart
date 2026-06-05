import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_assets.dart';

/// Compact world identifier badge — icon + name.
///
/// Used in world rails, lists, and navigation contexts to show
/// a recognizable world icon alongside the world name.
class VWorldBadge extends StatelessWidget {
  final String worldId;
  final String worldName;
  final double iconSize;
  final bool showName;
  final bool isSelected;
  final VoidCallback? onTap;

  const VWorldBadge({
    super.key,
    required this.worldId,
    required this.worldName,
    this.iconSize = 24,
    this.showName = true,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconData = WorldAssets.iconForWorld(worldId);

    final icon = Icon(
      iconData,
      size: iconSize,
      color: isSelected
          ? VColors.primary
          : (isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant),
    );

    if (!showName) {
      return onTap != null ? GestureDetector(onTap: onTap, child: icon) : icon;
    }

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: VSpacing.sm),
        Flexible(
          child: Text(
            worldName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: VFontSize.bodyMd,
              fontWeight: isSelected
                  ? VFontWeight.semiBold
                  : VFontWeight.regular,
              color: isSelected
                  ? VColors.primary
                  : (isDark ? VColors.onSurfaceDark : VColors.onSurface),
            ),
          ),
        ),
      ],
    );

    return onTap != null ? GestureDetector(onTap: onTap, child: row) : row;
  }
}
