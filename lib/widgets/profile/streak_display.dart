import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class StreakDisplay extends StatelessWidget {
  final int streakCount;
  final int streakShields;

  static const _milestones = [3, 7, 14, 30, 60, 90, 180, 365];

  const StreakDisplay({super.key, required this.streakCount, this.streakShields = 0});

  int? _nextMilestone() {
    for (final m in _milestones) {
      if (streakCount < m) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasStreak = streakCount > 0;
    final next = _nextMilestone();
    final daysToNext = next != null ? next - streakCount : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.warning.withValues(alpha: 0.08),
              AppColors.warning.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(RadiusTokens.card),
              ),
              child: Icon(
                Icons.local_fire_department,
                color: hasStreak ? AppColors.warning : theme.colorScheme.outlineVariant,
                size: IconSizes.lg,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasStreak ? '$streakCount Day Streak' : 'No active streak',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeights.bold,
                            color: hasStreak ? AppColors.warning : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (streakShields > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(RadiusTokens.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shield, size: 14, color: AppColors.primary),
                              const SizedBox(width: 3),
                              Text(
                                '$streakShields',
                                style: const TextStyle(
                                  fontSize: FontSizes.labelSm,
                                  fontWeight: FontWeights.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),
                  Row(
                    children: List.generate(7, (i) {
                      final dayIndex = 7 - i;
                      final isFilled = hasStreak && dayIndex <= streakCount;
                      return Container(
                        width: 22,
                        height: 22,
                        margin: EdgeInsets.only(right: i < 6 ? 4 : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled
                              ? AppColors.warning.withValues(alpha: 0.2 + (i * 0.08))
                              : theme.colorScheme.surfaceContainerHighest,
                          border: isFilled
                              ? Border.all(color: AppColors.warning.withValues(alpha: 0.35))
                              : Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
                        ),
                        child: isFilled ? Icon(Icons.check, size: 12, color: AppColors.warning) : null,
                      );
                    }),
                  ),
                  const SizedBox(height: Spacing.xs),
                  if (hasStreak && next != null)
                    Text(
                      '$daysToNext more day${daysToNext == 1 ? '' : 's'} to $next-day milestone!',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.warning.withValues(alpha: 0.8),
                        fontWeight: FontWeights.semiBold,
                      ),
                    )
                  else if (!hasStreak)
                    Text(
                      'Check in today to start your streak!',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                    )
                  else
                    Text(
                      'Maximum streak achieved. You are legendary!',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.warning.withValues(alpha: 0.8),
                        fontWeight: FontWeights.semiBold,
                      ),
                    ),
                ],
              ),
            ),
            if (hasStreak)
              Column(
                children: [
                  Text(
                    '$streakCount',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeights.bold,
                      color: AppColors.warning,
                    ),
                  ),
                  Text(
                    'days',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
