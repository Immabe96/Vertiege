import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/season_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/v_surface_card.dart';

/// Live season narrative from [global_seasons] on Nexus (Wave 20).
class SeasonNexusBanner extends StatelessWidget {
  const SeasonNexusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SeasonNarrativeSnapshot?>(
      future: SeasonService.fetchActiveSeasonNarrative(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null || data.narrative.trim().isEmpty) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.md,
            VSpacing.sm,
            VSpacing.md,
            0,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/season'),
              borderRadius: BorderRadius.circular(VRadius.lg),
              child: VSurfaceCard(
                padding: const EdgeInsets.all(VSpacing.md),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: VFontWeight.semiBold,
                    color: VColors.tertiary,
                  ),
                ),
                if (data.tagline.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    data.tagline,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: VSpacing.xs),
                Text(
                  data.narrative,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                ),
                const SizedBox(height: VSpacing.xs),
                Text(
                  'View season standings',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: VColors.primary,
                    fontWeight: VFontWeight.semiBold,
                  ),
                ),
              ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
