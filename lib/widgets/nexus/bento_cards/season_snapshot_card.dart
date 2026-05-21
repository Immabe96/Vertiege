import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/resident_provider.dart';
import '../../../state/world_provider.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/design_system.dart';

/// Small card with season name + user's worlds count.
class SeasonSnapshotCard extends ConsumerWidget {
  const SeasonSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final worldState = ref.watch(worldProvider);
    final worlds = worldState.worlds.values.toList();

    if (resident == null) return const SizedBox.shrink();

    final joinedCount = resident.joinedWorldIds.length;
    final totalWorlds = worlds.length;

    // Determine a season-like label based on current month
    final month = DateTime.now().month;
    final seasonLabel = switch (month) {
      >= 3 && <= 5 => 'Spring Season',
      >= 6 && <= 8 => 'Summer Season',
      >= 9 && <= 11 => 'Autumn Season',
      _ => 'Winter Season',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.auto_awesome,
              size: IconSizes.md,
              color: VColors.primary,
            ),
            const SizedBox(width: Spacing.xs),
            const Text(
              'SEASON',
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
          seasonLabel,
          style: const TextStyle(
            fontSize: FontSizes.bodyMd,
            fontWeight: FontWeights.bold,
            color: VColors.onSurface,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          '$joinedCount of $totalWorlds worlds joined',
          style: const TextStyle(
            fontSize: FontSizes.labelSm,
            color: VColors.outline,
          ),
        ),
        const SizedBox(height: Spacing.md),
        GestureDetector(
          onTap: () => context.push('/season'),
          child: const Row(
            children: [
              Text(
                'View Season',
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
        ),
      ],
    );
  }
}
