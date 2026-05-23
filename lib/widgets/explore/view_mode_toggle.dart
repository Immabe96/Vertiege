import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class ExploreViewToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ExploreViewToggle({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: VAnimation.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.sm,
            vertical: VSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? VColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(VRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: VIconSize.sm,
                color: selected ? VColors.primary : VColors.outline,
              ),
              const SizedBox(width: VSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: selected
                      ? VFontWeight.semiBold
                      : VFontWeight.regular,
                  color: selected ? VColors.primary : VColors.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
