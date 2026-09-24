import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class ExploreSectionHeader extends StatelessWidget {
  final String title;

  const ExploreSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm + 4,
        VSpacing.md,
        VSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: VColors.tertiary,
              borderRadius: BorderRadius.circular(VRadius.sm),
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: VFontSize.headlineLg,
                fontWeight: VFontWeight.semiBold,
                color: VColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
