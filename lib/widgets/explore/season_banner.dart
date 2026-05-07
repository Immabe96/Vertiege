import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/world.dart';
import '../../services/season_service.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class SeasonBanner extends StatelessWidget {
  final List<World> worlds;
  final VoidCallback onTap;

  const SeasonBanner({super.key, required this.worlds, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final season = SeasonService.getCurrentSeason(worlds: worlds);
    final subtitle = SeasonService.bannerSubtitle(season.scores);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(Spacing.lg),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(RadiusTokens.card),
            border: Border.all(
              color: AppColors.tertiary.withValues(alpha: AppColors.glowGoldAlpha * 2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.tertiary.withValues(alpha: 0.06),
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
                  color: AppColors.tertiary,
                  borderRadius: BorderRadius.circular(2),
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
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: FontSizes.bodyMd,
                        fontWeight: FontWeights.bold,
                        color: AppColors.tertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: FontSizes.labelSm,
                        color: AppColors.inkSecondary,
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
                  color: AppColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(RadiusTokens.lg),
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'VIEW SEASON RANKINGS',
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.bold,
                    color: AppColors.tertiary,
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
