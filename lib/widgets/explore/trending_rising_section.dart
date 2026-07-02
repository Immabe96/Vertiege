import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class TrendingRisingSection extends StatelessWidget {
  final String title;
  final List<World> worlds;
  final String badgeLabel;
  final Color badgeColor;

  const TrendingRisingSection({
    super.key,
    required this.title,
    required this.worlds,
    required this.badgeLabel,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.md,
            0,
            VSpacing.md,
            VSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(VRadius.sm),
                ),
              ),
              const SizedBox(width: VSpacing.sm),
              Text(
                title,
                style: TextStyle(
                  fontSize: VFontSize.headlineLg,
                  fontWeight: VFontWeight.semiBold,
                  color: badgeColor,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
            itemCount: worlds.length,
            separatorBuilder: (_, _) => const SizedBox(width: VSpacing.sm + 4),
            itemBuilder: (context, index) {
              final world = worlds[index];
              return GestureDetector(
                onTap: () => context.push(exploreWorldPath(world.id)),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(VSpacing.md),
                  decoration: BoxDecoration(
                    color: VColors.glassBackgroundDark,
                    borderRadius: BorderRadius.circular(
                      VRadius.md,
                    ),
                    border: Border.all(color: VColors.glassBorderDark),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(VRadius.md),
                        ),
                        child: Icon(
                          title == 'Trending'
                              ? Icons.trending_up
                              : Icons.trending_flat,
                          color: badgeColor,
                          size: VIconSize.md,
                        ),
                      ),
                      const SizedBox(width: VSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              world.name,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: VFontWeight.bold,
                                color: VColors.onSurfaceDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: VIconSize.xs,
                                  color: VColors.onSurfaceVariantDark,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${world.memberCount}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: VColors.onSurfaceVariantDark,
                                  ),
                                ),
                                const SizedBox(width: VSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: VSpacing.sm,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                      VRadius.sm,
                                    ),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      fontSize: VFontSize.labelSm,
                                      fontWeight: VFontWeight.bold,
                                      color: badgeColor,
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
        ),
      ],
    );
  }
}
