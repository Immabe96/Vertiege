import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Unread boundary — red accent pill (DCX-057).
class NewSinceVisitDivider extends StatelessWidget {
  const NewSinceVisitDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: VCommuneColors.statusDnd.withValues(alpha: 0.85),
              thickness: 1,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: VSpacing.sm),
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: VSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: VCommuneColors.statusDnd.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(VRadius.pill),
              border: Border.all(
                color: VCommuneColors.statusDnd.withValues(alpha: 0.45),
              ),
            ),
            child: const Text(
              'New since last visit',
              style: TextStyle(
                fontSize: VFontSize.labelSm,
                fontWeight: VFontWeight.bold,
                color: VCommuneColors.statusDnd,
                height: VLineHeight.label,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: VCommuneColors.statusDnd.withValues(alpha: 0.85),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
