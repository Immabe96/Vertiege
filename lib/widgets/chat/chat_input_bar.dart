import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;
  final VoidCallback? onAttach;
  final bool showAttach;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.hintText = 'Message...',
    this.onAttach,
    this.showAttach = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      blur: 10,
      borderRadius: BorderRadius.zero,
      padding: const EdgeInsets.fromLTRB(
        Spacing.sm + 4,
        Spacing.xs,
        Spacing.sm,
        Spacing.sm + 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showAttach)
            IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: onAttach,
              tooltip: 'Attach image',
              color: AppColors.inkMuted,
              iconSize: IconSizes.lg,
              padding: EdgeInsets.zero,
            ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: AppColors.inkMuted),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary),
                ),
                filled: true,
                fillColor: AppColors.glassBackground,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: 10,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded),
            color: AppColors.tertiary,
            iconSize: IconSizes.lg,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
