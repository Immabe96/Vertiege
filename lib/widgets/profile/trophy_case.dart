import 'package:flutter/material.dart';
import '../../models/resident.dart';
import '../../models/achievement.dart';
import '../../theme/v_colors.dart';
import '../shared/tier_icon.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import 'achievement_trophy_wall.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(VIcons.trophy, size: VIconSize.sm, color: VColors.tertiary),
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
            theme: theme,
          ),
          const SizedBox(height: VSpacing.md),

          // Prestige stars
          if (resident.prestigeStars > 0)
            _PrestigeStarsSection(
              stars: resident.prestigeStars,
              theme: theme,
            ),
          if (resident.prestigeStars > 0)
            const SizedBox(height: VSpacing.md),

          // Verified achievement wall
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Achievement wall',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.sm),
              AchievementTrophyWall(achievements: achievements),
            ],
          ),
          const SizedBox(height: VSpacing.md),

          // Streak milestones
          if (resident.streakCount > 0)
            _StreakMilestonesSection(
              streak: resident.streakCount,
              theme: theme,
            ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final Resident resident;
  final ThemeData theme;

  const _TimelineSection({
    required this.resident,
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
            color: theme.colorScheme.primary,
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
  final ThemeData theme;

  const _TimelineItem({
    required this.tier,
    required this.date,
    required this.isCurrent,
    required this.isLast,
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
              child: Center(
                child: TierIcon(tier: tier.value, size: VIconSize.lgMd),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                        color: isCurrent ? color : theme.colorScheme.onSurface,
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
                      color: theme.colorScheme.onSurfaceVariant,
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
  final ThemeData theme;

  const _PrestigeStarsSection({
    required this.stars,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final prestigeTitle = stars == 1 ? 'Apex I' : 'Apex $stars';
    const visibleStars = 5;
    final showStars = stars > visibleStars ? visibleStars : stars;
    final overflow = stars > visibleStars ? stars - visibleStars : 0;

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
                showStars,
                (i) => Padding(
                  padding: EdgeInsets.only(right: i < showStars - 1 ? 4 : 0),
                  child: const Icon(
                    VIcons.sparkles,
                    color: VColors.tertiary,
                    size: VIconSize.lg,
                  ),
                ),
              ),
              if (overflow > 0) ...[
                const SizedBox(width: VSpacing.xs),
                Text(
                  '+$overflow',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: VColors.tertiary,
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Text(
                  prestigeTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: VFontWeight.bold,
                    color: VColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StreakMilestonesSection extends StatelessWidget {
  final int streak;
  final ThemeData theme;

  const _StreakMilestonesSection({
    required this.streak,
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
            color: theme.colorScheme.primary,
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
                          : theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: m.reached
                            ? VColors.tertiary.withValues(alpha: 0.5)
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${m.days}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: m.reached
                              ? VColors.tertiary
                              : theme.colorScheme.onSurfaceVariant,
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
                          : theme.colorScheme.onSurfaceVariant,
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
