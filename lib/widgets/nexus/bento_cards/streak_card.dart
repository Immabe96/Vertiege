import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../state/resident_provider.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/v_tokens.dart';
import '../../../utils/streak_check_in.dart';

/// Nexus bento card — daily check-in streak and next milestone bonus.
class StreakCard extends ConsumerWidget {
  const StreakCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    if (resident == null) return const SizedBox.shrink();

    final streak = resident.streakCount;
    final bonus = streakBonusXp(streak);
    final nextMilestone = _nextMilestone(streak);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: VIconSize.md,
              color: streak > 0 ? VColors.brand : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: VSpacing.xs),
            Text(
              'STREAK',
              style: TextStyle(
                fontSize: VFontSize.labelSm,
                fontWeight: VFontWeight.semiBold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.sm),
        Text(
          '$streak',
          style: const TextStyle(
            fontSize: VFontSize.headlineLg,
            fontWeight: VFontWeight.extraBold,
            color: VColors.brand,
            height: 1,
          ),
        ),
        Text(
          streak == 1 ? 'day' : 'days',
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: VSpacing.sm),
        Text(
          bonus > 0
              ? '+$bonus XP milestone'
              : nextMilestone != null
              ? '$nextMilestone-day bonus ahead'
              : resident.streakShields > 0
              ? '${resident.streakShields} shield${resident.streakShields == 1 ? '' : 's'}'
              : 'Check in daily',
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            color: Theme.of(context).colorScheme.outline,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  int? _nextMilestone(int streak) {
    const milestones = [3, 7, 14, 30, 60, 90, 180, 365];
    for (final m in milestones) {
      if (streak < m) return m;
    }
    return null;
  }
}
