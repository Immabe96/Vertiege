import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        itemCount: worlds.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.md),
        itemBuilder: (context, index) {
          final world = worlds[index];
          return GestureDetector(
            onTap: () => context.push('/explore/${world.id}'),
            child: Container(
              width: 200,
              padding: const EdgeInsets.all(Spacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.tertiary.withValues(alpha: 0.1),
                    AppColors.tertiary.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
                border: Border.all(
                  color: AppColors.tertiary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    child: const Icon(Icons.rocket_launch, color: AppColors.tertiary, size: IconSizes.md),
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
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.bolt, size: 12, color: AppColors.tertiary),
                            const SizedBox(width: 2),
                            Text(
                              'Boosted',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.tertiary,
                                fontWeight: FontWeights.semiBold,
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Text(
                              '★ P${world.prestige}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.inkMuted,
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
