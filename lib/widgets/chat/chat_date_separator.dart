import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class ChatDateSeparator extends StatelessWidget {
  final String label;

  const ChatDateSeparator({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor = isDark ? VColors.glassBorderDark : VColors.glassBorder;
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
                color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
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
