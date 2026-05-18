import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../theme/colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';

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
            onTap: () => context.push('/explore/${world.id}'),
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
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: VColors.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: const Icon(VIcons.rocket, color: VColors.tertiary, size: VIconSize.md),
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
                            color: VColors.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.bolt, size: 12, color: VColors.tertiary),
                            const SizedBox(width: 2),
                            Text(
                              'Boosted',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: VColors.tertiary,
                                fontWeight: VFontWeight.semiBold,
                              ),
                            ),
                            const SizedBox(width: VSpacing.sm),
                            Text(
                              '★ P${world.prestige}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: VColors.onSurfaceVariant,
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
