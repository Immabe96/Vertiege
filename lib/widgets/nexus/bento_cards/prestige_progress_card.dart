import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/achievements.dart';
import '../../../state/resident_provider.dart';
import '../../../state/achievement_provider.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/v_tokens.dart';
import '../../shared/tier_icon.dart';

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
    final nextThreshold = tierNum < 5
        ? (xpThresholds[tierNum + 1] ?? totalXp + 1)
        : totalXp + 1;
    final tierProgress = totalXp - currentThreshold;
    final tierRequired = nextThreshold - currentThreshold;
    final progressFraction = tierRequired > 0
        ? (tierProgress / tierRequired).clamp(0.0, 1.0)
        : 0.0;

    final tierColor = switch (tierNum) {
      5 => VColors.tierApex,
      4 => VColors.tierOldMoney,
      3 => VColors.tierElite,
      2 => VColors.tierHighRoller,
      _ => VColors.tierHustler,
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
            SizedBox(
              width: 32,
              height: 32,
              child: TierIcon(tier: tierNum, size: 32),
            ),
            const SizedBox(width: VSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tierLabel.toUpperCase(),
                  style: const TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.semiBold,
                    color: VColors.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  '$totalXp XP',
                  style: const TextStyle(
                    fontSize: VFontSize.headlineMd,
                    fontWeight: VFontWeight.bold,
                    color: VColors.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: VSpacing.sm),
        if (tierNum < 5) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next: $nextTierLabel',
                style: const TextStyle(
                  fontSize: VFontSize.labelSm,
                  color: VColors.outline,
                ),
              ),
              Text(
                '${tierRequired - tierProgress} XP',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                  color: tierColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.sm),
            child: LinearProgressIndicator(
              value: progressFraction,
              minHeight: 4,
              backgroundColor: VColors.glassBorder,
              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
            ),
          ),
        ] else ...[
          const SizedBox(height: VSpacing.xs),
          Text(
            'SOVEREIGN MAX',
            style: TextStyle(
              fontSize: VFontSize.labelSm,
              fontWeight: VFontWeight.bold,
              color: tierColor,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.sm),
            child: LinearProgressIndicator(
              value: 1.0,
              minHeight: 4,
              backgroundColor: VColors.glassBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(
                VColors.tierApex,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
