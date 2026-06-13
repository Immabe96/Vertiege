import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import '../worlds/world_icon.dart';

class BoostedWorldsRow extends StatelessWidget {
  final List<World> worlds;

  const BoostedWorldsRow({super.key, required this.worlds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
        itemCount: worlds.length,
        separatorBuilder: (_, _) => const SizedBox(width: VSpacing.md),
        itemBuilder: (context, index) {
          final world = worlds[index];
          return GestureDetector(
            onTap: () => context.push(exploreWorldPath(world.id)),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(VSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    VColors.tertiary.withValues(alpha: 0.1),
                    VColors.tertiary.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(VRadius.lg),
                border: Border.all(
                  color: VColors.tertiary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  WorldIcon(
                    worldId: world.assetKey,
                    size: 40,
                    useGlassContainer: false,
                    circular: true,
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          world.name,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: VFontWeight.bold,
                            color: VColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.bolt, size: VIconSize.xs, color: VColors.tertiary),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                'Boosted',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: VColors.tertiary,
                                  fontWeight: VFontWeight.semiBold,
                                ),
                              ),
                            ),
                            const SizedBox(width: VSpacing.sm),
                            Flexible(
                              child: Text(
                                '★ P${world.prestige}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: VColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
