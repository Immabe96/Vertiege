import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../state/challenge_provider.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/design_system.dart';

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
              size: IconSizes.md,
              color: VColors.secondary,
            ),
            const SizedBox(width: Spacing.xs),
            const Text(
              'CHALLENGES',
              style: TextStyle(
                fontSize: FontSizes.labelSm,
                fontWeight: FontWeights.semiBold,
                color: VColors.onSurfaceVariant,
                letterSpacing: LetterSpacing.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          '$activeCount Active',
          style: const TextStyle(
            fontSize: FontSizes.headlineMd,
            fontWeight: FontWeights.bold,
            color: VColors.onSurface,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        if (inProgressCount > 0)
          Text(
            '$inProgressCount in progress',
            style: const TextStyle(
              fontSize: FontSizes.labelSm,
              color: VColors.outline,
            ),
          )
        else
          const Text(
            'Tap to view challenges',
            style: TextStyle(
              fontSize: FontSizes.labelSm,
              color: VColors.outline,
            ),
          ),
        const SizedBox(height: Spacing.md),
        const Row(
          children: [
            Text(
              'View All',
              style: TextStyle(
                fontSize: FontSizes.labelSm,
                color: VColors.primary,
              ),
            ),
            SizedBox(width: Spacing.xs),
            Icon(
              Icons.chevron_right,
              size: IconSizes.sm,
              color: VColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
