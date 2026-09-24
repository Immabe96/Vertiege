import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/season_catalog.dart';
import '../../../services/season_service.dart';
import '../../../state/resident_provider.dart';
import '../../../state/world_provider.dart';
import '../../../theme/v_tokens.dart';
import '../../../utils/calm_ranking.dart';

/// Nexus bento tile — Season 1 snapshot (tap handled by parent [BentoCard]).
class SeasonSnapshotCard extends ConsumerWidget {
  const SeasonSnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final worlds = ref.watch(worldProvider).worlds.values.toList();

    if (resident == null) return const SizedBox.shrink();

    final def = SeasonCatalog.active;
    final joinedCount = resident.joinedWorldIds.length;
    final unclaimed = SeasonService.unclaimedWorlds(worlds).length;
    final growing = SeasonService.growingWorldCount(worlds);
    final activeResidents = worlds.fold<int>(
      0,
      (sum, w) => sum + w.memberCount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: VIconSize.md,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: VSpacing.xs),
            Text(
              'SEASON 1',
              style: TextStyle(
                fontSize: VFontSize.labelSm,
                fontWeight: VFontWeight.semiBold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.sm),
        Text(
          'The Big Bang',
          style: TextStyle(
            fontSize: VFontSize.bodyMd,
            fontWeight: VFontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          def.tagline,
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            color: Theme.of(context).colorScheme.outline,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          '$unclaimed open · $growing growing · $joinedCount joined',
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            color: Theme.of(context).colorScheme.primary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          CalmRanking.activeResidentsLabel(activeResidents),
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
}
