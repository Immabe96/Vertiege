import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';

class SovereignStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final VoidCallback? onTap;

  const SovereignStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassPanel(
        useBlur: false,
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg, horizontal: Spacing.sm),
        borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: IconSizes.lg, color: AppColors.tertiary.withValues(alpha: 0.7)),
            const SizedBox(height: Spacing.sm),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AnimDurations.entrance,
              curve: AnimCurves.bouncy,
              builder: (context, progress, _) {
                return Transform.scale(
                  scale: progress,
                  child: Opacity(
                    opacity: progress,
                    child: Text(
                      '$value',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: FontSizes.displayXl,
                        fontWeight: FontWeights.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                letterSpacing: LetterSpacing.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
