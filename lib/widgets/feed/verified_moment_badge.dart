import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';

/// Label for proof-backed Nexus standing posts.
class VerifiedMomentBadge extends StatelessWidget {
  const VerifiedMomentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.sm,
        vertical: VSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: VColors.brand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: Border.all(color: VColors.brand.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            VIcons.badgeCheck,
            size: VIconSize.sm,
            color: VColors.brand,
          ),
          const SizedBox(width: VSpacing.xxs),
          Text(
            'Verified moment',
            style: TextStyle(
              fontSize: VFontSize.labelSm,
              fontWeight: VFontWeight.semiBold,
              color: VCommuneColors.headerPrimaryOf(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
