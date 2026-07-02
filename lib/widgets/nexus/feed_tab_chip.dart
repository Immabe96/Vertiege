import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class FeedTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const FeedTabChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VAnimation.fast,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? VColors.primary.withValues(alpha: 0.18)
              : VColors.glassBackgroundDark,
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(
            color: selected
                ? VColors.primary.withValues(alpha: 0.35)
                : VColors.glassBorderDark,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: VIconSize.denseSm,
                color: selected ? VColors.primary : VColors.onSurfaceVariantDark,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? VColors.onSurfaceDark
                    : VColors.onSurfaceVariantDark,
                fontWeight: selected ? VFontWeight.semiBold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
