import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/achievements.dart';
import '../../models/achievement.dart';
import '../../state/resident_provider.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_colors.dart';
import 'package:vertiege/ui/ui.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/screen_loading.dart';
import '../../ui/cards/v_card.dart';
import '../../widgets/journey/progress_trail.dart';

class AscensionPathScreen extends ConsumerWidget {
  const AscensionPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final resident = ref.watch(residentProvider).resident;
    final achievementState = ref.watch(achievementProvider);

    if (resident == null) {
      return const VHubPage(
        title: 'Ascension Path',
        showBack: true,
        body: ScreenLoading.list(),
      );
    }

    final totalXp = achievementState.totalXp;
    final currentTier = resident.tier;
    final tierNum = currentTier.value;

    // Calculate XP for next tier
    final nextThreshold = tierNum < 5 ? (xpThresholds[tierNum + 1] ?? 0) : 0;
    final xpToNext = tierNum < 5
        ? (nextThreshold - totalXp).clamp(0, 999999)
        : 0;

    // Achievements at this tier
    final verifiedCount = achievementState.userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .length;
    final submittedCount = achievementState.userAchievements
        .where((a) => a.status == AchievementStatus.submitted)
        .length;

    return VHubPage(
      title: 'Ascension Path',
      showBack: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.md),
        child: Column(
          children: [
            // Title
            const Text(
              'Ascension Path',
              style: TextStyle(
                fontSize: VFontSize.displayXl,
                fontWeight: VFontWeight.bold,
                color: VColors.tertiary,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              'Your journey through the tiers',
              style: TextStyle(
                fontSize: VFontSize.bodyMd,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.xl),

            // Progress Trail
            Center(child: ProgressTrail(currentTier: tierNum)),
            const SizedBox(height: VSpacing.lg),

            // XP Stats
            VCard(
              padding: const EdgeInsets.all(VSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXPERIENCE',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.semiBold,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total XP',
                        style: TextStyle(fontSize: VFontSize.bodyMd),
                      ),
                      Text(
                        '$totalXp',
                        style: const TextStyle(
                          fontSize: VFontSize.headlineMd,
                          fontWeight: VFontWeight.bold,
                          color: VColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Current Tier',
                        style: TextStyle(fontSize: VFontSize.bodyMd),
                      ),
                      Text(
                        currentTier.label,
                        style: TextStyle(
                          fontSize: VFontSize.bodyMd,
                          fontWeight: VFontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tierNum < 5 ? 'Next Tier' : 'Max Tier',
                        style: const TextStyle(fontSize: VFontSize.bodyMd),
                      ),
                      Text(
                        tierNum < 5 ? '$xpToNext XP needed' : 'Sovereign',
                        style: TextStyle(
                          fontSize: VFontSize.bodyMd,
                          fontWeight: VFontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Verified Achievements',
                        style: TextStyle(fontSize: VFontSize.bodyMd),
                      ),
                      Text(
                        '$verifiedCount${submittedCount > 0 ? ' (+$submittedCount pending)' : ''}',
                        style: TextStyle(
                          fontSize: VFontSize.bodyMd,
                          fontWeight: VFontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (verifiedCount > 0 && tierNum < 5) ...[
                    const SizedBox(height: VSpacing.sm),
                    Text(
                      '$verifiedCount of ${{1: 0, 2: 500, 3: 2000, 4: 10000, 5: 50000}[tierNum + 1] ?? 0} XP from achievements',
                      style: TextStyle(
                        fontSize: VFontSize.labelSm,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: VSpacing.lg),

            // Button to Hall of Ascension
            VButton(
              label: 'View Hall of Ascension',
              icon: const Icon(VIcons.chart, size: VIconSize.md),
              isFullWidth: true,
              size: ButtonSize.large,
              onPressed: () => context.push('/hall-of-ascension'),
            ),
          ],
        ),
      ),
    );
  }
}
