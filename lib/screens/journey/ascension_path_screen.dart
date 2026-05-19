import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/achievements.dart';
import '../../models/achievement.dart';
import '../../state/resident_provider.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/loading_state.dart';
import '../../widgets/core/glass_panel.dart';
import '../../widgets/journey/progress_trail.dart';
import '../../ui/icons/v_icons.dart';

class AscensionPathScreen extends ConsumerWidget {
  const AscensionPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;
    final achievementState = ref.watch(achievementProvider);

    if (resident == null) {
      return Scaffold(
        backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
        appBar: AppBar(title: const Text('Ascension Path')),
        body: const SafeArea(child: GlassLoadingList(itemCount: 3)),
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

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
        elevation: 0,
        title: Text(
          'Ascension Path',
          style: GoogleFonts.manrope(
            fontSize: FontSizes.headlineMd,
            fontWeight: FontWeights.bold,
            color: VColors.tertiary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(

          child: Column(
            children: [
              // Title
              Text(
                'Ascension Path',
                style: GoogleFonts.manrope(
                  fontSize: FontSizes.displayXl,
                  fontWeight: FontWeights.bold,
                  color: VColors.tertiary,
                  letterSpacing: LetterSpacing.display,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xs),
              Text(
                'Your journey through the tiers',
                style: TextStyle(
                  fontSize: FontSizes.bodyMd,
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xl),

              // Progress Trail
              Center(child: ProgressTrail(currentTier: tierNum)),
              const SizedBox(height: Spacing.lg),

              // XP Stats
              FCard(
                useBlur: false,

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EXPERIENCE',
                      style: TextStyle(
                        fontSize: FontSizes.labelSm,
                        fontWeight: FontWeights.semiBold,
                        letterSpacing: LetterSpacing.label,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total XP',
                          style: TextStyle(fontSize: FontSizes.bodyMd),
                        ),
                        Text(
                          '$totalXp',
                          style: const TextStyle(
                            fontSize: FontSizes.headlineMd,
                            fontWeight: FontWeights.bold,
                            color: VColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Tier',
                          style: TextStyle(fontSize: FontSizes.bodyMd),
                        ),
                        Text(
                          currentTier.label,
                          style: TextStyle(
                            fontSize: FontSizes.bodyMd,
                            fontWeight: FontWeights.bold,
                            color: isDark
                                ? VColors.onSurfaceDark
                                : VColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tierNum < 5 ? 'Next Tier' : 'Max Tier',
                          style: TextStyle(fontSize: FontSizes.bodyMd),
                        ),
                        Text(
                          tierNum < 5 ? '$xpToNext XP needed' : 'Sovereign',
                          style: TextStyle(
                            fontSize: FontSizes.bodyMd,
                            fontWeight: FontWeights.bold,
                            color: isDark
                                ? VColors.onSurfaceDark
                                : VColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verified Achievements',
                          style: TextStyle(fontSize: FontSizes.bodyMd),
                        ),
                        Text(
                          '$verifiedCount${submittedCount > 0 ? ' (+$submittedCount pending)' : ''}',
                          style: TextStyle(
                            fontSize: FontSizes.bodyMd,
                            fontWeight: FontWeights.bold,
                            color: isDark
                                ? VColors.onSurfaceDark
                                : VColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    if (verifiedCount > 0 && tierNum < 5) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        '$verifiedCount of ${{1: 0, 2: 500, 3: 2000, 4: 10000, 5: 50000}[tierNum + 1] ?? 0} XP from achievements',
                        style: TextStyle(
                          fontSize: FontSizes.labelSm,
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // Button to Hall of Ascension
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => context.push('/hall-of-ascension'),
                  icon: const Icon(VIcons.chart, size: IconSizes.md),
                  label: const Text(
                    'View Hall of Ascension',
                    style: TextStyle(
                      fontSize: FontSizes.bodyMd,
                      fontWeight: FontWeights.semiBold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: VColors.tertiary,
                    foregroundColor: VColors.onTertiary,

                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
