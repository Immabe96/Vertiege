import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/achievements.dart';
import '../../../state/resident_provider.dart';
import '../../../state/achievement_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_system.dart';

/// Medium card with tier name + XP progress bar.
class PrestigeProgressCard extends ConsumerWidget {
  const PrestigeProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final achievementState = ref.watch(achievementProvider);
    final totalXp = achievementState.totalXp;

    if (resident == null) return const SizedBox.shrink();

    final tier = resident.tier;
    final tierLabel = tier.label;
    final tierNum = tier.value;

    // Calculate progress toward next tier
    final currentThreshold = xpThresholds[tierNum] ?? 0;
    final nextThreshold = tierNum < 5 ? (xpThresholds[tierNum + 1] ?? totalXp + 1) : totalXp + 1;
    final tierProgress = totalXp - currentThreshold;
    final tierRequired = nextThreshold - currentThreshold;
    final progressFraction = tierRequired > 0
        ? (tierProgress / tierRequired).clamp(0.0, 1.0)
        : 0.0;

    final tierColor = switch (tierNum) {
      5 => AppColors.tierApex,
      4 => AppColors.tierOldMoney,
      3 => AppColors.tierElite,
      2 => AppColors.tierHighRoller,
      _ => AppColors.tierHustler,
    };

    final nextTierLabel = tierNum < 5
        ? (['High Roller', 'Elite', 'Old Money', 'Apex'])[tierNum - 1]
        : 'MAX';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(RadiusTokens.sm),
              ),
              child: Icon(
                Icons.shield, // Will be overridden by switch below
                size: IconSizes.sm,
                color: tierColor,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tierLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.semiBold,
                    color: AppColors.inkSecondary,
                    letterSpacing: LetterSpacing.label,
                  ),
                ),
                Text(
                  '$totalXp XP',
                  style: const TextStyle(
                    fontSize: FontSizes.headlineMd,
                    fontWeight: FontWeights.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        if (tierNum < 5) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next: $nextTierLabel',
                style: const TextStyle(fontSize: FontSizes.labelSm, color: AppColors.inkMuted),
              ),
              Text(
                '${tierRequired - tierProgress} XP',
                style: TextStyle(fontSize: FontSizes.labelSm, fontWeight: FontWeights.semiBold, color: tierColor),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 4,
              backgroundColor: AppColors.glassBorder,
              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
            ),
          ),
        ] else ...[
          const SizedBox(height: Spacing.xs),
          Text(
            'SOVEREIGN MAX',
            style: TextStyle(fontSize: FontSizes.labelSm, fontWeight: FontWeights.bold, color: tierColor),
          ),
          const SizedBox(height: Spacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: 1.0,
              minHeight: 4,
              backgroundColor: AppColors.glassBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.tierApex),
            ),
          ),
        ],
      ],
    );
  }
}
