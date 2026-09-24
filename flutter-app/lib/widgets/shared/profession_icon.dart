import 'package:flutter/material.dart';

import '../../config/cosmetics.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/asset_image_decode.dart';

/// Profession emblem from generated assets, with icon fallback.
class ProfessionIcon extends StatelessWidget {
  final String? profession;
  final double size;
  final Color? fallbackColor;

  const ProfessionIcon({
    super.key,
    required this.profession,
    this.size = VBadgeSize.profession,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final cosmetic =
        profession != null && profession!.isNotEmpty
            ? professionCosmetics[profession]
            : null;

    if (cosmetic == null) {
      return Icon(
        Icons.work_outline,
        size: size,
        color: fallbackColor ?? VColors.onSurfaceVariant,
      );
    }

    final inset = VBadgeSize.artInset(size);
    final inner = VBadgeSize.artInner(size);
    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: Image.asset(
          cosmetic.iconAsset,
          width: inner,
          height: inner,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          cacheWidth: assetCachePx(context, inner),
          errorBuilder: (_, _, _) => Icon(
            Icons.work_outline,
            size: inner * VBadgeSize.fallbackIconFraction,
            color: fallbackColor ?? cosmetic.color,
          ),
        ),
      ),
    );
  }
}
