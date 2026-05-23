import 'package:flutter/material.dart';
import '../../config/cosmetics.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../../utils/asset_image_decode.dart';
import '../../utils/world_assets.dart';
import '../../ui/icons/v_icons.dart';

class Badge extends StatelessWidget {
  final String decorationId;

  const Badge({super.key, required this.decorationId});

  @override
  Widget build(BuildContext context) {
    final label = decorationLabels[decorationId] ?? 'Verified Professional';
    final imagePath = WorldAssets.badgeImageForId(decorationId);

    return Chip(
      avatar: imagePath != null
          ? Image.asset(
              imagePath,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              cacheWidth: assetCachePx(context, 22),
              errorBuilder: (_, _, _) => const Icon(VIcons.sparkles, size: 16),
            )
          : const Icon(VIcons.sparkles, size: 16),
      label: Text(label, style: const TextStyle(fontSize: FontSizes.micro)),
      backgroundColor: VColors.surfaceContainerHighest,
      side: BorderSide.none,
      padding: const EdgeInsets.all(4),
    );
  }
}
