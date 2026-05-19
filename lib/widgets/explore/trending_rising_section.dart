import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            0,
            Spacing.md,
            Spacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                title,
                style: TextStyle(
                  fontSize: FontSizes.headlineLg,
                  fontWeight: FontWeights.semiBold,
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
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            itemCount: worlds.length,
            separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm + 4),
            itemBuilder: (context, index) {
              final world = worlds[index];
              return GestureDetector(
                onTap: () => context.push('/explore/${world.id}'),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
                    borderRadius: BorderRadius.circular(
                      RadiusTokens.cardFeatured,
                    ),
                    border: Border.all(color: isDark ? VColors.glassBorderDark : VColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(RadiusTokens.md),
                        ),
                        child: Icon(
                          title == 'Trending'
                              ? Icons.trending_up
                              : Icons.trending_flat,
                          color: badgeColor,
                          size: IconSizes.md,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              world.name,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeights.bold,
                                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 12,
                                  color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${world.memberCount}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
                                  ),
                                ),
                                const SizedBox(width: Spacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Spacing.sm,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(
                                      RadiusTokens.chip,
                                    ),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      fontSize: FontSizes.labelSm,
                                      fontWeight: FontWeights.bold,
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
