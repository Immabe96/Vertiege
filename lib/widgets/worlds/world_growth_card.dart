import 'package:flutter/material.dart';

import '../../config/tiers.dart';
import '../../config/world_capability_matrix.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Level / growth narrative on world detail (dominion activity or prestige).
class WorldGrowthCard extends StatelessWidget {
  final World world;

  const WorldGrowthCard({super.key, required this.world});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final growth = WorldCapabilityMatrix.worldGrowth(world);
    final isDominion = world.type == WorldType.dominion;
    final capacity = isDominion
        ? getResidentCapacity(growth.level)
        : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        VSpacing.xs,
      ),
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? VColors.surfaceContainerDark
            : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isDark
              ? VColors.outlineVariantDark.withValues(alpha: 0.25)
              : VColors.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDominion ? Icons.trending_up : Icons.auto_awesome,
                size: VIconSize.md,
                color: VColors.tertiary,
              ),
              const SizedBox(width: VSpacing.xs),
              Text(
                isDominion ? 'World growth' : 'World prestige',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.sm,
                  vertical: VSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: VColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
                child: Text(
                  isDominion ? 'Level ${growth.level}' : 'Prestige ${world.prestige}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: VColors.primary,
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          if (isDominion) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.pill),
              child: LinearProgressIndicator(
                value: growth.isMax ? 1.0 : growth.fraction,
                minHeight: 8,
                backgroundColor: isDark
                    ? VColors.surfaceContainerHighDark
                    : VColors.surfaceContainerHigh,
              ),
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              growth.isMax
                  ? '${growth.activityScore} activity · max level'
                  : '${growth.activityScore} activity · ${growth.progress}/${growth.range} to level ${growth.level + 1}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
            if (capacity != null) ...[
              const SizedBox(height: VSpacing.xxs),
              Text(
                'Resident cap: $capacity',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: VColors.tertiary,
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
            ],
          ] else
            Text(
              'Prestige ${world.prestige}/50 unlocks lounge, marketplace, treasury, and governance.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          if (WorldCapabilityMatrix.worldHasMarketplace(world) ||
              WorldCapabilityMatrix.worldHasTreasury(world)) ...[
            const SizedBox(height: VSpacing.sm),
            Wrap(
              spacing: VSpacing.xs,
              runSpacing: VSpacing.xxs,
              children: [
                if (WorldCapabilityMatrix.worldHasTreasury(world))
                  _FeatureChip(label: 'Treasury open'),
                if (WorldCapabilityMatrix.worldHasMarketplace(world))
                  _FeatureChip(label: 'Marketplace open'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: VColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: VFontSize.labelSm,
          color: VColors.success,
          fontWeight: VFontWeight.semiBold,
        ),
      ),
    );
  }
}
