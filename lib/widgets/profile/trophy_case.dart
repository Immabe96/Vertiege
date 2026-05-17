import 'package:flutter/material.dart';
import '../../models/resident.dart';
import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class TrophyCase extends StatelessWidget {
  final Resident resident;
  final List<UserAchievement> achievements;
  final int totalXp;

  const TrophyCase({
    super.key,
    required this.resident,
    required this.achievements,
    required this.totalXp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, size: VIconSize.sm, color: VColors.tertiary),
              const SizedBox(width: VSpacing.xs),
              Text(
                'Trophy Case',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),

          // Tier journey timeline
          _TimelineSection(
            resident: resident,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: VSpacing.md),

          // Prestige stars
          if (resident.prestigeStars > 0)
            _PrestigeStarsSection(
              stars: resident.prestigeStars,
              isDark: isDark,
              theme: theme,
            ),
          if (resident.prestigeStars > 0)
            const SizedBox(height: VSpacing.md),

          // Top achievements
          _RecentAchievementsSection(
            achievements: achievements,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: VSpacing.md),

          // Streak milestones
          if (resident.streakCount > 0)
            _StreakMilestonesSection(
              streak: resident.streakCount,
              isDark: isDark,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final Resident resident;
  final bool isDark;
  final ThemeData theme;

  const _TimelineSection({
    required this.resident,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final tierHistory = _buildTierHistory();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tier Journey',
          style: theme.textTheme.labelMedium?.copyWith(
            color: VColors.primary,
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.sm),
        ...tierHistory.asMap().entries.map((entry) {
          final index = entry.key;
          final tierEntry = entry.value;
          final isCurrent = index == 0;
          return _TimelineItem(
            tier: tierEntry.tier,
            date: tierEntry.date,
            isCurrent: isCurrent,
            isLast: index == tierHistory.length - 1,
            isDark: isDark,
            theme: theme,
          );
        }),
      ],
    );
  }

  List<({ResidentTier tier, String? date})> _buildTierHistory() {
    final tiers = <({ResidentTier tier, String? date})>[];
    tiers.add((tier: resident.tier, date: _formatDate(resident.lastActivityAt)));

    if (resident.tier.value > 1) {
      tiers.add((tier: ResidentTier.fromValue(resident.tier.value - 1), date: null));
    }
    if (resident.tier.value > 2) {
      tiers.add((tier: ResidentTier.fromValue(resident.tier.value - 2), date: null));
    }
    if (resident.tier.value > 3) {
      tiers.add((tier: ResidentTier.fromValue(resident.tier.value - 3), date: null));
    }
    if (resident.tier.value > 4) {
      tiers.add((tier: ResidentTier.fromValue(resident.tier.value - 4), date: null));
    }

    return tiers;
  }

  String? _formatDate(int? timestamp) {
    if (timestamp == null || timestamp == 0) return null;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TimelineItem extends StatelessWidget {
  final ResidentTier tier;
  final String? date;
  final bool isCurrent;
  final bool isLast;
  final bool isDark;
  final ThemeData theme;

  const _TimelineItem({
    required this.tier,
    required this.date,
    required this.isCurrent,
    required this.isLast,
    required this.isDark,
    required this.theme,
  });

  Color _tierColor(int value) {
    switch (value) {
      case 5:
        return VColors.tierApex;
      case 4:
        return VColors.tierOldMoney;
      case 3:
        return VColors.tierElite;
      case 2:
        return VColors.tierHighRoller;
      default:
        return VColors.tierHustler;
    }
  }

  IconData _tierIcon(int value) {
    switch (value) {
      case 5:
        return Icons.diamond;
      case 4:
        return Icons.rocket_launch;
      case 3:
        return Icons.star;
      case 2:
        return Icons.star_border;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(tier.value);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isCurrent ? 0.2 : 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: isCurrent ? 0.6 : 0.3),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Icon(
                _tierIcon(tier.value),
                size: 16,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isDark
                    ? VColors.outlineVariantDark.withValues(alpha: 0.3)
                    : VColors.outlineVariant.withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: VSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      tier.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent ? VFontWeight.bold : VFontWeight.regular,
                        color: isCurrent ? color : (isDark ? VColors.onSurfaceDark : VColors.onSurface),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: VSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.xs,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        child: Text(
                          'Current',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: VFontWeight.bold,
                            fontSize: VFontSize.labelSm,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (date != null)
                  Text(
                    'Achieved $date',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PrestigeStarsSection extends StatelessWidget {
  final int stars;
  final bool isDark;
  final ThemeData theme;

  const _PrestigeStarsSection({
    required this.stars,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final prestigeTitle = stars == 1 ? 'Apex I' : 'Apex $stars';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prestige',
          style: theme.textTheme.labelMedium?.copyWith(
            color: VColors.tertiary,
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.sm),
        Container(
          padding: const EdgeInsets.all(VSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VColors.tertiary.withValues(alpha: 0.15),
                VColors.secondary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(VRadius.lg),
            border: Border.all(
              color: VColors.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              ...List.generate(
                stars,
                (i) => Padding(
                  padding: EdgeInsets.only(right: i < stars - 1 ? 6 : 0),
                  child: const Icon(Icons.star, color: VColors.tertiary, size: 28),
                ),
              ),
              const SizedBox(width: VSpacing.md),
              Text(
                prestigeTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                  color: VColors.tertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentAchievementsSection extends StatelessWidget {
  final List<UserAchievement> achievements;
  final bool isDark;
  final ThemeData theme;

  const _RecentAchievementsSection({
    required this.achievements,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final verified = achievements
        .where((a) => a.status == AchievementStatus.verified)
        .take(5)
        .toList();

    if (verified.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Achievements',
          style: theme.textTheme.labelMedium?.copyWith(
            color: VColors.primary,
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.sm),
        Wrap(
          spacing: VSpacing.sm,
          runSpacing: VSpacing.sm,
          children: verified.map((a) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.sm,
                vertical: VSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: VColors.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(VRadius.pill),
                border: Border.all(
                  color: VColors.tertiary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 14, color: VColors.tertiary),
                  const SizedBox(width: VSpacing.xxs),
                  Text(
                    a.achievementId,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: VColors.tertiary,
                      fontWeight: VFontWeight.semiBold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StreakMilestonesSection extends StatelessWidget {
  final int streak;
  final bool isDark;
  final ThemeData theme;

  const _StreakMilestonesSection({
    required this.streak,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final milestones = [
      (days: 7, label: 'Week Warrior', reached: streak >= 7),
      (days: 14, label: 'Fortnight', reached: streak >= 14),
      (days: 30, label: 'Month Master', reached: streak >= 30),
      (days: 90, label: 'Season Sage', reached: streak >= 90),
      (days: 365, label: 'Year Legend', reached: streak >= 365),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Streak Milestones',
          style: theme.textTheme.labelMedium?.copyWith(
            color: VColors.primary,
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.sm),
        Row(
          children: milestones.map((m) {
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: m.reached
                          ? VColors.tertiary.withValues(alpha: 0.2)
                          : (isDark
                              ? VColors.glassBackgroundDark
                              : VColors.glassBackground),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: m.reached
                            ? VColors.tertiary.withValues(alpha: 0.5)
                            : (isDark
                                ? VColors.glassBorderDark
                                : VColors.glassBorder),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${m.days}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: m.reached
                              ? VColors.tertiary
                              : (isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant),
                          fontWeight: m.reached
                              ? VFontWeight.bold
                              : VFontWeight.regular,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: m.reached
                          ? VColors.tertiary
                          : (isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant),
                      fontSize: VFontSize.labelSm,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
