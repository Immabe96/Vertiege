import 'package:flutter/material.dart';
import '../../models/world.dart';
import '../../services/season_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class SeasonBanner extends StatelessWidget {
  final List<World> worlds;
  final VoidCallback onTap;

  const SeasonBanner({super.key, required this.worlds, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final season = SeasonService.getCurrentSeason(worlds: worlds);
    final subtitle = SeasonService.bannerSubtitle(season.scores);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(VSpacing.lg),
          decoration: BoxDecoration(
            color: VColors.glassBackgroundDark,
            borderRadius: BorderRadius.circular(VRadius.lg),
            border: Border.all(color: VColors.glassBorderDark),
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
                  borderRadius: BorderRadius.circular(VRadius.sm),
                ),
              ),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      season.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: VFontSize.bodyMd,
                        fontWeight: VFontWeight.bold,
                        color: VColors.tertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: VFontSize.labelSm,
                        color: VColors.onSurfaceVariantDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: VSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.md,
                  vertical: VSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: VColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VRadius.lg),
                  border: Border.all(
                    color: VColors.tertiary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Text(
                  'VIEW SEASON RANKINGS',
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.bold,
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
