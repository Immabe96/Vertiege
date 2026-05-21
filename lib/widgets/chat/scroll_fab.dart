import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

class ChatScrollFab extends StatelessWidget {
  final VoidCallback onTap;
  final Color? backgroundColor;

  const ChatScrollFab({super.key, required this.onTap, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: backgroundColor ?? (isDark ? VColors.glassBackgroundDark : VColors.glassBackground),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
            size: IconSizes.lg,
          ),
        ),
      ),
    );
  }
}
