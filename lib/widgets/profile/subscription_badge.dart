import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class SubscriptionBadge extends StatelessWidget {
  final SubscriptionTier tier;

  const SubscriptionBadge({super.key, required this.tier});

  @override
  Widget build(BuildContext context) {
    final benefits = SubscriptionService.getBenefits(tier);
    final label = benefits['badgeLabel'] as String;
    if (label.isEmpty) return const SizedBox.shrink();

    final isSovereign = tier == SubscriptionTier.sovereignElite;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VColors.tertiary, VColors.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(VRadius.pill),
        boxShadow: [
          BoxShadow(
            color: VColors.tertiary.withValues(
              alpha: isSovereign ? 0.35 : 0.15,
            ),
            blurRadius: isSovereign ? 12 : 6,
            spreadRadius: isSovereign ? 2 : 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSovereign ? Icons.diamond : Icons.star,
            size: 14,
            color: VColors.onTertiary,
          ),
          const SizedBox(width: VSpacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: VFontSize.labelSm,
              fontWeight: VFontWeight.bold,
              color: VColors.onTertiary,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
