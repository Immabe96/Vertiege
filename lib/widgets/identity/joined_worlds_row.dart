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
    final isDark = theme.brightness == Brightness.dark;

    if (worlds.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
        child: Text(
          'No worlds joined yet — explore and join a community.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? VColors.onSurfaceVariantDark
                : VColors.onSurfaceVariant,
          ),
        ),
      );
    }

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
        itemCount: worlds.length,
        separatorBuilder: (_, _) => const SizedBox(width: VSpacing.sm),
        itemBuilder: (context, index) {
          final world = worlds[index];
          return Material(
            color: isDark
                ? VColors.surfaceContainerDark
                : VColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(VRadius.lg),
            child: InkWell(
              borderRadius: BorderRadius.circular(VRadius.lg),
              onTap: () => context.push(exploreWorldPath(world.id)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.md,
                  vertical: VSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WorldIcon(worldId: world.id, size: 40),
                    const SizedBox(width: VSpacing.sm),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        world.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: VFontWeight.semiBold,
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
