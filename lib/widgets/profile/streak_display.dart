import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class StreakDisplay extends StatelessWidget {
  final int streakCount;
  final int streakShields;
  final String? questNudge;

  static const _milestones = [3, 7, 14, 30, 60, 90, 180, 365];

  const StreakDisplay({
    super.key,
    required this.streakCount,
    this.streakShields = 0,
    this.questNudge,
  });

  int? _nextMilestone() {
    for (final m in _milestones) {
      if (streakCount < m) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasStreak = streakCount > 0;
    final next = _nextMilestone();
    final daysToNext = next != null ? next - streakCount : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(VSpacing.md),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VColors.warning.withValues(alpha: 0.08),
              VColors.warning.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(VRadius.md),
          border: Border.all(color: VColors.warning.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: VColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(VRadius.lg),
              ),
              child: Icon(
                Icons.local_fire_department,
                color: hasStreak
                    ? VColors.warning
                    : isDark ? VColors.outlineVariantDark : theme.colorScheme.outlineVariant,
                size: VIconSize.lg,
              ),
            ),
            const SizedBox(width: VSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasStreak
                              ? '$streakCount Day Streak'
                              : 'No active streak',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: VFontWeight.bold,
                            color: hasStreak
                                ? VColors.warning
                                : isDark ? VColors.onSurfaceVariantDark : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (streakShields > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: VColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              VRadius.pill,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield,
                                size: 14,
                                color: VColors.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$streakShields',
                                style: const TextStyle(
                                  fontSize: VFontSize.labelSm,
                                  fontWeight: VFontWeight.bold,
                                  color: VColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.xs),
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
                              ? VColors.warning.withValues(
                                  alpha: 0.2 + (i * 0.08),
                                )
                              : isDark ? VColors.surfaceContainerHighestDark : theme.colorScheme.surfaceContainerHighest,
                          border: isFilled
                              ? Border.all(
                                  color: VColors.warning.withValues(
                                    alpha: 0.35,
                                  ),
                                )
                              : Border.all(
                                  color: (isDark ? VColors.outlineVariantDark : theme.colorScheme.outlineVariant)
                                      .withValues(alpha: 0.2),
                                ),
                        ),
                        child: isFilled
                            ? Icon(
                                Icons.check,
                                size: 12,
                                color: VColors.warning,
                              )
                            : null,
                      );
                    }),
                  ),
                  const SizedBox(height: VSpacing.xs),
                  if (hasStreak && next != null)
                    Text(
                      '$daysToNext more day${daysToNext == 1 ? '' : 's'} to $next-day milestone!',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: VColors.warning.withValues(alpha: 0.8),
                        fontWeight: VFontWeight.semiBold,
                      ),
                    )
                  else if (!hasStreak)
                    Text(
                      'Check in today to start your streak!',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? VColors.outlineDark : theme.colorScheme.outline,
                      ),
                    )
                  else
                    Text(
                      'Maximum streak achieved. You are legendary!',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: VColors.warning.withValues(alpha: 0.8),
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                  if (questNudge != null && questNudge!.isNotEmpty) ...[
                    const SizedBox(height: VSpacing.xs),
                    Text(
                      questNudge!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (hasStreak)
              Column(
                children: [
                  Text(
                    '$streakCount',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: VFontWeight.bold,
                      color: VColors.warning,
                    ),
                  ),
                  Text(
                    'days',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: VColors.warning.withValues(alpha: 0.7),
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
