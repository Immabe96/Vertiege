import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class ExploreSectionHeader extends StatelessWidget {
  final String title;

  const ExploreSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md, Spacing.sm + 4, Spacing.md, Spacing.xs),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: FontSizes.headlineLg,
                fontWeight: FontWeights.semiBold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
