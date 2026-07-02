import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';

import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../worlds/world_icon.dart';

/// Horizontal chips for worlds the resident has joined.
class JoinedWorldsRow extends StatelessWidget {
  final List<World> worlds;

  const JoinedWorldsRow({super.key, required this.worlds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (worlds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
        child: Text(
          'No worlds joined yet — explore and join a community.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: VColors.onSurfaceVariantDark,
          ),
        ),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
        itemCount: worlds.length,
        separatorBuilder: (_, _) => const SizedBox(width: VSpacing.md),
        itemBuilder: (context, index) {
          final world = worlds[index];
          return InkWell(
            onTap: () => context.push(exploreWorldPath(world.id)),
            borderRadius: BorderRadius.circular(VRadius.md),
            child: SizedBox(
              width: 72,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  WorldIcon(
                    worldId: world.assetKey,
                    size: 52,
                    useGlassContainer: false,
                  ),
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    world.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: VFontWeight.semiBold,
                      color: VColors.onSurfaceDark,
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
