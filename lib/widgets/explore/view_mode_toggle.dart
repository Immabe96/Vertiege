import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

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
          duration: AnimDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? VColors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: IconSizes.sm,
                color: selected ? VColors.primary : VColors.outline,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontSize: FontSizes.labelSm,
                  fontWeight: selected
                      ? FontWeights.semiBold
                      : FontWeights.regular,
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
