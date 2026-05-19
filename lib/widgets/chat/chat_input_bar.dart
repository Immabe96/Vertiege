import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
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
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: GlassPanel(
        blur: 10,
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.fromLTRB(
          Spacing.sm,
          replyToName != null ? Spacing.xs : Spacing.xs,
          Spacing.sm,
          Spacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyToName != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                decoration: BoxDecoration(
                  color: VColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                  border: Border.all(
                    color: VColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.reply_rounded,
                      size: IconSizes.sm,
                      color: VColors.primary,
                    ),
                    const SizedBox(width: Spacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to $replyToName',
                            style: TextStyle(
                              fontSize: FontSizes.labelSm,
                              fontWeight: FontWeights.semiBold,
                              color: VColors.primary,
                            ),
                          ),
                          if (replyToContent != null)
                            Text(
                              replyToContent!,
                              style: TextStyle(
                                fontSize: FontSizes.labelXs,
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
                        icon: const Icon(VIcons.x, size: IconSizes.sm),
                        onPressed: onCancelReply,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            if (replyToName != null) const SizedBox(height: Spacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showAttach)
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: onAttach,
                    tooltip: 'Attach image',
                    color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
                    iconSize: IconSizes.lg,
                    padding: EdgeInsets.zero,
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
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
                        horizontal: Spacing.md,
                        vertical: Spacing.sm,
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
                  icon: const Icon(VIcons.send),
                  color: VColors.tertiary,
                  iconSize: IconSizes.lg,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            if (typingIndicator != null && typingIndicator!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, left: Spacing.md),
                child: Text(
                  typingIndicator!,
                  style: TextStyle(
                    fontSize: FontSizes.labelXs,
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
