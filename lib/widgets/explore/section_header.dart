import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

class ExploreSectionHeader extends StatelessWidget {
  final String title;

  const ExploreSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm + 4,
        Spacing.md,
        Spacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: VColors.tertiary,
              borderRadius: BorderRadius.circular(RadiusTokens.sm),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: FontSizes.headlineLg,
                fontWeight: FontWeights.semiBold,
                color: VColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
