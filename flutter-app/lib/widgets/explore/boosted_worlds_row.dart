import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/world_resident_count_label.dart';
import '../worlds/world_banner.dart';
import '../worlds/world_icon.dart';

class BoostedWorldsRow extends StatelessWidget {
  final List<World> worlds;

  const BoostedWorldsRow({super.key, required this.worlds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
        itemCount: worlds.length,
        separatorBuilder: (_, _) => const SizedBox(width: VSpacing.md),
        itemBuilder: (context, index) {
          final world = worlds[index];
          return GestureDetector(
            onTap: () => context.push(exploreWorldPath(world.id)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.lg),
              child: SizedBox(
                width: 240,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    WorldBanner(
                      worldId: world.id,
                      assetKey: world.assetKey,
                      width: 240,
                      height: 148,
                      worldType: world.type,
                      prestige: world.prestige,
                      contained: true,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x26000000),
                            Color(0xB8000000),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: VSpacing.md,
                      right: VSpacing.md,
                      bottom: VSpacing.md,
                      child: Row(
                        children: [
                          WorldIcon(
                            worldId: world.assetKey,
                            size: VWorldIconSize.dense,
                            useGlassContainer: false,
                            circular: true,
                          ),
                          const SizedBox(width: VSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  world.name,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: VFontWeight.bold,
                                    color: VColors.onSurfaceDark,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '★ P${world.prestige} · ${worldMemberCountLabel(world.memberCount)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: VColors.onSurfaceVariantDark,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: VSpacing.sm,
                      right: VSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: VColors.tertiary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        child: Text(
                          'Featured',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: VColors.onTertiary,
                            fontWeight: VFontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
