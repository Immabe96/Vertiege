import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Divider marking messages received since the user's last channel visit.
class NewSinceVisitDivider extends StatelessWidget {
  const NewSinceVisitDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.md),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: VColors.primary, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.sm),
            child: Text(
              'New since last visit',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: VFontSize.labelSm,
                fontWeight: VFontWeight.semiBold,
                color: VColors.primary,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: VColors.primary, thickness: 1),
          ),
        ],
      ),
    );
  }
}
