import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.tertiary, AppColors.tertiaryFixedDim],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        boxShadow: [
          BoxShadow(
            color: AppColors.tertiary.withValues(alpha: isSovereign ? 0.35 : 0.15),
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
            color: AppColors.onTertiary,
          ),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: const TextStyle(
              fontSize: FontSizes.labelSm,
              fontWeight: FontWeights.bold,
              color: AppColors.onTertiary,
              letterSpacing: LetterSpacing.label,
            ),
          ),
        ],
      ),
    );
  }
}
