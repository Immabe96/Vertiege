import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../utils/world_assets.dart';

class TierIcon extends StatelessWidget {
  final int tier;
  final double size;

  const TierIcon({super.key, required this.tier, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final imagePath = WorldAssets.tierImageForValue(tier);
    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
            .round()
            .clamp(48, 256),
        errorBuilder: (_, _, _) => _fallbackIcon(),
      );
    }

    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    final icon = switch (tier) {
      5 => Icons.flag,
      4 => Icons.shield,
      3 => Icons.local_police,
      2 => Icons.diamond,
      _ => Icons.trending_up,
    };
    final color = switch (tier) {
      5 => VColors.tierApex,
      4 => VColors.tierOldMoney,
      3 => VColors.tierElite,
      2 => VColors.tierHighRoller,
      _ => VColors.tierHustler,
    };

    return Icon(icon, size: size, color: color);
  }
}
