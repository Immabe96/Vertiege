import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class ChatDateSeparator extends StatelessWidget {
  final String label;

  const ChatDateSeparator({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.glassBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.inkMuted,
                fontWeight: FontWeights.regular,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.glassBorder)),
        ],
      ),
    );
  }
}
