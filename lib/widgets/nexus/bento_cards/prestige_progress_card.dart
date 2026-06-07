import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/achievements.dart';
import '../../../config/progression_glossary.dart';
import '../../../state/resident_provider.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/v_tokens.dart';
import '../../core/progression_help_sheet.dart';
import '../../shared/tier_icon.dart';

/// Medium card with tier name + XP progress bar.
class PrestigeProgressCard extends ConsumerWidget {
  const PrestigeProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    if (resident == null) return const SizedBox.shrink();

    final totalXp = resident.totalXp;

    final tier = resident.tier;
    final tierLabel = tier.label;
    final tierNum = tier.value;

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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showProgressionHelp(
          context,
          focus: ProgressionFocus.xpAndTier,
        ),
        borderRadius: BorderRadius.circular(VRadius.md),
        child: Column(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR TIER',
                        style: TextStyle(
                          fontSize: VFontSize.labelSm,
                          fontWeight: VFontWeight.semiBold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        tierLabel.toUpperCase(),
                        style: TextStyle(
                          fontSize: VFontSize.labelSm,
                          fontWeight: VFontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$totalXp XP',
                        style: TextStyle(
                          fontSize: VFontSize.headlineMd,
                          fontWeight: VFontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.help_outline,
                  size: VIconSize.sm,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: VSpacing.xxs),
            Text(
              ProgressionGlossary.xpToNextTier(totalXp, tierNum),
              style: TextStyle(
                fontSize: VFontSize.labelSm,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            if (tierNum < 5)
              ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.sm),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 4,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(VRadius.sm),
                child: LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 4,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(VColors.tierApex),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
