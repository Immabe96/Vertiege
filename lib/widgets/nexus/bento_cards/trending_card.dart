import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../router/world_navigation.dart';
import '../../../state/world_provider.dart';
import '../../../theme/v_colors.dart';
import '../../../theme/v_tokens.dart';

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
    final worlds =
        worldState.worlds.values.where((w) => w.memberCount > 0).toList()
          ..sort((a, b) => b.prestige.compareTo(a.prestige));

    final trending = worlds.take(3).toList();

    if (trending.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.trending_up,
              size: VIconSize.sm,
              color: VColors.primary,
            ),
            const SizedBox(width: VSpacing.xs),
            const Text(
              'TRENDING WORLDS',
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
        ...trending.asMap().entries.map((entry) {
          final index = entry.key;
          final world = entry.value;
          final iconData = _iconMap[world.icon] ?? Icons.public;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < trending.length - 1 ? VSpacing.sm : 0,
            ),
            child: InkWell(
              onTap: () => context.push(exploreWorldPath(world.id)),
              borderRadius: BorderRadius.circular(VRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: VSpacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: VColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(VRadius.sm),
                      ),
                      child: Icon(
                        iconData,
                        size: VIconSize.sm,
                        color: VColors.primary,
                      ),
                    ),
                    const SizedBox(width: VSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            world.name,
                            style: const TextStyle(
                              fontSize: VFontSize.bodyMd,
                              fontWeight: VFontWeight.bold,
                              color: VColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Prestige ${world.prestige}  •  ${world.memberCount} members',
                            style: const TextStyle(
                              fontSize: VFontSize.labelSm,
                              color: VColors.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: VColors.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: const TextStyle(
                          fontSize: VFontSize.labelSm,
                          fontWeight: VFontWeight.bold,
                          color: VColors.tertiary,
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
