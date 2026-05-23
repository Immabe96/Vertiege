import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/resident_provider.dart';
import '../../../state/world_provider.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/v_tokens.dart';

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
              size: VIconSize.md,
              color: VColors.primary,
            ),
            const SizedBox(width: VSpacing.xs),
            const Text(
              'SEASON',
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
          seasonLabel,
          style: const TextStyle(
            fontSize: VFontSize.bodyMd,
            fontWeight: VFontWeight.bold,
            color: VColors.onSurface,
          ),
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          '$joinedCount of $totalWorlds worlds joined',
          style: const TextStyle(
            fontSize: VFontSize.labelSm,
            color: VColors.outline,
          ),
        ),
        const SizedBox(height: VSpacing.md),
        GestureDetector(
          onTap: () => context.push('/season'),
          child: const Row(
            children: [
              Text(
                'View Season',
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
        ),
      ],
    );
  }
}
