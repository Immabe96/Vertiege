import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// A glass-style filter pill used in horizontal chip rows.
///
/// Typically used for filter bars and contextual chip rows throughout the app.
class FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const FilterPill({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VAnimation.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? VColors.primary.withValues(alpha: 0.12)
              : VColors.glassBackground,
          borderRadius: BorderRadius.circular(VRadius.lg),
          border: Border.all(
            color: selected
                ? VColors.primary.withValues(alpha: 0.3)
                : VColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: VIconSize.sm,
              color: selected ? VColors.primary : VColors.outline,
            ),
            const SizedBox(width: VSpacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: VFontSize.bodyMd,
                fontWeight: selected ? VFontWeight.bold : VFontWeight.regular,
                color: selected ? VColors.primary : VColors.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
