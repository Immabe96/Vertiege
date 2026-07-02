import 'package:flutter/material.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Floating pill divider between chat days (DCX-056).
class ChatDateSeparator extends StatelessWidget {
  final String label;
  final bool useCommuneStyle;

  const ChatDateSeparator({
    super.key,
    required this.label,
    this.useCommuneStyle = true,
  });

  @override
  Widget build(BuildContext context) {
    if (useCommuneStyle) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: VSpacing.md),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: VSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: VCommuneColors.surfaceFloating,
              borderRadius: BorderRadius.circular(VRadius.pill),
              border: Border.all(color: VCommuneColors.dividerSubtle),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: VFontSize.labelSm,
                fontWeight: VFontWeight.semiBold,
                color: VCommuneColors.textMuted,
                height: VLineHeight.label,
              ),
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final dividerColor = VCommuneColors.dividerSubtle;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.md),
      child: Row(
        children: [
          Expanded(child: Divider(color: dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: VCommuneColors.textMuted,
                fontWeight: VFontWeight.regular,
              ),
            ),
          ),
          Expanded(child: Divider(color: dividerColor)),
        ],
      ),
    );
  }
}
