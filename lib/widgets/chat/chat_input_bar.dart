import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/glass_panel.dart';
import '../../ui/icons/v_icons.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;
  final VoidCallback? onAttach;
  final bool showAttach;
  final String? replyToName;
  final String? replyToContent;
  final VoidCallback? onCancelReply;
  final String? typingIndicator;
  final ValueChanged<String>? onChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.hintText = 'Message...',
    this.onAttach,
    this.showAttach = false,
    this.replyToName,
    this.replyToContent,
    this.onCancelReply,
    this.typingIndicator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: VSurfacePanel(
        blur: 10,
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.fromLTRB(
          VSpacing.sm,
          replyToName != null ? VSpacing.xs : VSpacing.xs,
          VSpacing.sm,
          VSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyToName != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.sm,
                  vertical: VSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: VColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(VRadius.md),
                  border: Border.all(
                    color: VColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.reply_rounded,
                      size: VIconSize.sm,
                      color: VColors.primary,
                    ),
                    const SizedBox(width: VSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to $replyToName',
                            style: TextStyle(
                              fontSize: VFontSize.labelSm,
                              fontWeight: VFontWeight.semiBold,
                              color: VColors.primary,
                            ),
                          ),
                          if (replyToContent != null)
                            Text(
                              replyToContent!,
                              style: TextStyle(
                                fontSize: VFontSize.labelSm,
                                color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (onCancelReply != null)
                      IconButton(
                        icon: const Icon(VIcons.x, size: VIconSize.sm),
                        onPressed: onCancelReply,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            if (replyToName != null) const SizedBox(height: VSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showAttach)
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: onAttach,
                    tooltip: 'Attach image',
                    color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
                    iconSize: VIconSize.lg,
                    padding: EdgeInsets.zero,
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: TextStyle(color: isDark ? VColors.onSurfaceDark : VColors.onSurface),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(color: isDark ? VColors.onSurfaceVariantDark : VColors.outline),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: VColors.glassBorder),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: VColors.glassBorder),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: VColors.primary),
                      ),
                      filled: true,
                      fillColor: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: VSpacing.md,
                        vertical: VSpacing.sm,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                IconButton(
                  onPressed: onSend,
                  icon: const Icon(VIcons.send),
                  color: VColors.tertiary,
                  iconSize: VIconSize.lg,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            if (typingIndicator != null && typingIndicator!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: VSpacing.md),
                child: Text(
                  typingIndicator!,
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
