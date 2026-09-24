import 'package:flutter/material.dart';
import '../../config/cosmetics.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_assets.dart';
import '../../ui/icons/v_icons.dart';
import '../shared/badge_asset_image.dart';

class Badge extends StatelessWidget {
  final String decorationId;

  const Badge({super.key, required this.decorationId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = decorationLabels[decorationId] ?? 'Verified Professional';
    final imagePath = WorldAssets.badgeImageForId(decorationId);
    final chipBg = theme.colorScheme.surfaceContainerHigh;
    final hasRaster = imagePath != null;

    return Chip(
      avatar: hasRaster
          ? BadgeAssetImage(
              imagePath: imagePath,
              size: VBadgeSize.decorationChip,
              errorBuilder: (_, _, _) =>
                  const Icon(VIcons.sparkles, size: VIconSize.sm),
            )
          : const Icon(VIcons.sparkles, size: VIconSize.sm),
      label: Text(label, style: const TextStyle(fontSize: VFontSize.labelSm)),
      backgroundColor: hasRaster ? Colors.transparent : chipBg,
      side: BorderSide.none,
      padding: const EdgeInsets.all(4),
    );
  }
}
