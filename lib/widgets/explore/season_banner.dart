import 'package:flutter/material.dart';
import '../../models/world.dart';
import '../../services/season_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

class SeasonBanner extends StatelessWidget {
  final List<World> worlds;
  final VoidCallback onTap;

  const SeasonBanner({super.key, required this.worlds, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final season = SeasonService.getCurrentSeason(worlds: worlds);
    final subtitle = SeasonService.bannerSubtitle(season.scores);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
            borderRadius: BorderRadius.circular(RadiusTokens.card),
            border: Border.all(
              color: isDark ? VColors.glassBorderDark : VColors.tertiary.withValues(
                alpha: 0.3 * 2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: VColors.tertiary.withValues(alpha: 0.06),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 56,
                decoration: BoxDecoration(
                  color: VColors.tertiary,
                  borderRadius: BorderRadius.circular(RadiusTokens.sm),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      season.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: FontSizes.bodyMd,
                        fontWeight: FontWeights.bold,
                        color: VColors.tertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: FontSizes.labelSm,
                        color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: VColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  border: Border.all(
                    color: VColors.tertiary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'VIEW SEASON RANKINGS',
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.bold,
                    color: VColors.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
