import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/cards/v_card.dart';

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
      child: VCard(
        padding: const EdgeInsets.symmetric(
          vertical: VSpacing.lg,
          horizontal: VSpacing.sm,
        ),
        borderRadius: BorderRadius.circular(VRadius.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: VIconSize.lg,
              color: VColors.tertiary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: VSpacing.sm),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: VAnimation.entrance,
              curve: Curves.elasticOut,
              builder: (context, progress, _) {
                return Transform.scale(
                  scale: progress,
                  child: Opacity(
                    opacity: progress,
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: VFontSize.displayXl,
                        fontWeight: VFontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
