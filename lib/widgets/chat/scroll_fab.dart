import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class ChatScrollFab extends StatelessWidget {
  final VoidCallback onTap;
  final Color? backgroundColor;

  const ChatScrollFab({super.key, required this.onTap, this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: backgroundColor ?? AppColors.glassBackground,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(Spacing.sm),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.ink,
            size: IconSizes.lg,
          ),
        ),
      ),
    );
  }
}
