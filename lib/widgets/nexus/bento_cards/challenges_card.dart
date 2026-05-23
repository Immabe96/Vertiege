import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/challenge_provider.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/v_tokens.dart';

class ChallengesCard extends ConsumerWidget {
  const ChallengesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeState = ref.watch(challengeProvider);
    final challenges = challengeState.activeChallenges;
    final progress = challengeState.userProgress;

    final activeCount = challenges.length;
    final inProgressCount = progress.entries
        .where(
          (e) =>
              !e.value.completed &&
              challenges.any((c) => c.id == e.key),
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.emoji_events,
              size: VIconSize.md,
              color: VColors.secondary,
            ),
            const SizedBox(width: VSpacing.xs),
            const Text(
              'CHALLENGES',
              style: TextStyle(
                fontSize: VFontSize.labelSm,
                fontWeight: VFontWeight.semiBold,
                color: VColors.onSurfaceVariant,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.sm),
        Text(
          '$activeCount Active',
          style: const TextStyle(
            fontSize: VFontSize.headlineMd,
            fontWeight: VFontWeight.bold,
            color: VColors.onSurface,
          ),
        ),
        const SizedBox(height: VSpacing.xs),
        if (inProgressCount > 0)
          Text(
            '$inProgressCount in progress',
            style: const TextStyle(
              fontSize: VFontSize.labelSm,
              color: VColors.outline,
            ),
          )
        else
          const Text(
            'Tap to view challenges',
            style: TextStyle(
              fontSize: VFontSize.labelSm,
              color: VColors.outline,
            ),
          ),
        const SizedBox(height: VSpacing.md),
        const Row(
          children: [
            Text(
              'View All',
              style: TextStyle(
                fontSize: VFontSize.labelSm,
                color: VColors.primary,
              ),
            ),
            SizedBox(width: VSpacing.xs),
            Icon(
              Icons.chevron_right,
              size: VIconSize.sm,
              color: VColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
