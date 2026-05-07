import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../state/world_provider.dart';
import '../../../theme/colors.dart';
import '../../../theme/design_system.dart';

/// Large card with 3 trending world rows.
class TrendingCard extends ConsumerWidget {
  const TrendingCard({super.key});

  static const _iconMap = {
    'public': Icons.public,
    'landscape': Icons.landscape,
    'science': Icons.science,
    'account_balance': Icons.account_balance,
    'rocket': Icons.rocket,
    'palette': Icons.palette,
    'music_note': Icons.music_note,
    'code': Icons.code,
    'earth': Icons.public,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldState = ref.watch(worldProvider);
    final worlds = worldState.worlds.values
        .where((w) => w.memberCount > 0)
        .toList()
      ..sort((a, b) => b.prestige.compareTo(a.prestige));

    final trending = worlds.take(3).toList();

    if (trending.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up, size: IconSizes.sm, color: AppColors.primary),
            const SizedBox(width: Spacing.xs),
            const Text(
              'TRENDING WORLDS',
              style: TextStyle(
                fontSize: FontSizes.labelSm,
                fontWeight: FontWeights.semiBold,
                color: AppColors.inkSecondary,
                letterSpacing: LetterSpacing.label,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        ...trending.asMap().entries.map((entry) {
          final index = entry.key;
          final world = entry.value;
          final iconData = _iconMap[world.icon] ?? Icons.public;

          return Padding(
            padding: EdgeInsets.only(bottom: index < trending.length - 1 ? Spacing.sm : 0),
            child: InkWell(
              onTap: () => context.push('/explore/${world.id}'),
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      ),
                      child: Icon(iconData, size: IconSizes.sm, color: AppColors.primary),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            world.name,
                            style: const TextStyle(
                              fontSize: FontSizes.bodyMd,
                              fontWeight: FontWeights.bold,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Prestige ${world.prestige}  •  ${world.memberCount} members',
                            style: const TextStyle(fontSize: FontSizes.labelSm, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          fontSize: FontSizes.labelSm,
                          fontWeight: FontWeights.bold,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
