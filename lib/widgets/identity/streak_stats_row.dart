import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/streak_check_in.dart';

/// Identity tab — day streak, shields, and next milestone (prototype streak row).
class StreakStatsRow extends StatelessWidget {
  final int streakCount;
  final int streakShields;

  const StreakStatsRow({
    super.key,
    required this.streakCount,
    required this.streakShields,
  });

  @override
  Widget build(BuildContext context) {
    final nextBonus = _nextMilestoneBonus(streakCount);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: VSpacing.md,
        horizontal: VSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: PrestigeNoir.surfaceRaised,
        borderRadius: BorderRadius.circular(VRadius.bento),
        border: Border.all(color: PrestigeNoir.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StreakStat(
              value: '$streakCount',
              label: 'Day streak',
              accent: true,
              icon: Icons.local_fire_department,
            ),
          ),
          Expanded(
            child: _StreakStat(
              value: '$streakShields',
              label: 'Shields',
              icon: Icons.shield_outlined,
            ),
          ),
          Expanded(
            child: _StreakStat(
              value: nextBonus > 0 ? '+$nextBonus' : '—',
              label: 'Next bonus',
              accent: nextBonus > 0,
            ),
          ),
          Expanded(
            child: _StreakStat(
              value: streakBonusXp(streakCount) > 0
                  ? '+${streakBonusXp(streakCount)}'
                  : '—',
              label: 'At milestone',
            ),
          ),
        ],
      ),
    );
  }

  int _nextMilestoneBonus(int streak) {
    const milestones = [3, 7, 14, 30, 60, 90, 180, 365];
    for (final m in milestones) {
      if (streak < m) return streakBonusXp(m);
    }
    return 0;
  }
}

class _StreakStat extends StatelessWidget {
  final String value;
  final String label;
  final bool accent;
  final IconData? icon;

  const _StreakStat({
    required this.value,
    required this.label,
    this.accent = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(
            icon,
            size: VIconSize.sm,
            color: accent ? VColors.brand : theme.colorScheme.onSurfaceVariant,
          ),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: VFontWeight.extraBold,
            color: accent ? VColors.brand : theme.colorScheme.onSurface,
            height: 1.1,
          ),
        ),
        const SizedBox(height: VSpacing.xxs),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
