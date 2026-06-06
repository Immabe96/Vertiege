import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/glass_panel.dart';
import '../../ui/icons/v_icons.dart';
import 'chat_attachment_tray.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;
  final VoidCallback? onAttach;
  final VoidCallback? onShareAchievement;
  final bool showAttach;
  final bool useAttachmentTray;
  final String? replyToName;
  final String? replyToContent;
  final VoidCallback? onCancelReply;
  final String? typingIndicator;
  final ValueChanged<String>? onChanged;
  final Widget? slashCommandBar;
  final VoidCallback? onOpenMediaPicker;

  /// Solid commune composer (world channels / DMs) instead of glass blur.
  final bool useCommuneStyle;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.hintText = 'Message...',
    this.onAttach,
    this.onShareAchievement,
    this.showAttach = false,
    this.useAttachmentTray = false,
    this.replyToName,
    this.replyToContent,
    this.onCancelReply,
    this.typingIndicator,
    this.onChanged,
    this.slashCommandBar,
    this.onOpenMediaPicker,
    this.useCommuneStyle = false,
  });

  static const double _maxComposerHeight = 120;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final composer = TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
        ),
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
        fillColor: useCommuneStyle
            ? VCommuneColors.surfaceTertiaryOf(brightness)
            : (isDark ? VColors.glassBackgroundDark : VColors.glassBackground),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.sm,
        ),
      ),
      minLines: 1,
      maxLines: useCommuneStyle ? 6 : 5,
      keyboardType: useCommuneStyle
          ? TextInputType.multiline
          : TextInputType.text,
      textInputAction:
          useCommuneStyle ? TextInputAction.newline : TextInputAction.send,
      onSubmitted: useCommuneStyle ? null : (_) => onSend(),
    );

    final constrainedComposer = useCommuneStyle
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: _maxComposerHeight),
            child: composer,
          )
        : composer;

    final field = useCommuneStyle
        ? Shortcuts(
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.enter): SendMessageIntent(),
              SingleActivator(LogicalKeyboardKey.enter, shift: true):
                  NewlineInComposerIntent(),
            },
            child: Actions(
              actions: {
                SendMessageIntent: CallbackAction<SendMessageIntent>(
                  onInvoke: (_) {
                    onSend();
                    return null;
                  },
                ),
                NewlineInComposerIntent: CallbackAction<NewlineInComposerIntent>(
                  onInvoke: (_) {
                    final text = controller.text;
                    final selection = controller.selection;
                    final insertAt = selection.baseOffset < 0
                        ? text.length
                        : selection.baseOffset;
                    final next = text.replaceRange(insertAt, insertAt, '\n');
                    controller.value = TextEditingValue(
                      text: next,
                      selection: TextSelection.collapsed(offset: insertAt + 1),
                    );
                    return null;
                  },
                ),
              },
              child: constrainedComposer,
            ),
          )
        : constrainedComposer;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (slashCommandBar != null) slashCommandBar!,
        if (replyToName != null) _ReplyQuoteBlock(
          replyToName: replyToName!,
          replyToContent: replyToContent,
          onCancelReply: onCancelReply,
          useCommuneStyle: useCommuneStyle,
          isDark: isDark,
        ),
        if (replyToName != null) const SizedBox(height: VSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (onOpenMediaPicker != null)
              IconButton(
                icon: const Icon(Icons.gif_box_outlined),
                onPressed: onOpenMediaPicker,
                tooltip: 'GIF & stickers',
                color: useCommuneStyle
                    ? VCommuneColors.textMuted
                    : (isDark ? VColors.onSurfaceVariantDark : VColors.outline),
                iconSize: VIconSize.lg,
                padding: EdgeInsets.zero,
              ),
            if (showAttach)
              IconButton(
                icon: Icon(
                  useAttachmentTray ? Icons.add_circle_outline : Icons.image_outlined,
                ),
                onPressed: () {
                  if (useAttachmentTray) {
                    showChatAttachmentTray(
                      context,
                      onAttachImage: onAttach,
                      onShareAchievement: onShareAchievement,
                    );
                  } else {
                    onAttach?.call();
                  }
                },
                tooltip: useAttachmentTray ? 'Add attachment' : 'Attach image',
                color: useCommuneStyle
                    ? VCommuneColors.textMuted
                    : (isDark ? VColors.onSurfaceVariantDark : VColors.outline),
                iconSize: VIconSize.lg,
                padding: EdgeInsets.zero,
              ),
            Expanded(child: field),
            const SizedBox(width: VSpacing.sm),
            IconButton(
              onPressed: onSend,
              icon: const Icon(VIcons.send),
              color: useCommuneStyle
                  ? VCommuneColors.textLink
                  : VColors.tertiary,
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
    );

    return SafeArea(
      top: false,
      child: useCommuneStyle
          ? ColoredBox(
              color: VCommuneColors.surfaceSecondaryOf(brightness),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.sm,
                  VSpacing.xs,
                  VSpacing.sm,
                  VSpacing.sm,
                ),
                child: content,
              ),
            )
          : VSurfacePanel(
              blur: 10,
              borderRadius: BorderRadius.zero,
              padding: const EdgeInsets.fromLTRB(
                VSpacing.sm,
                VSpacing.xs,
                VSpacing.sm,
                VSpacing.sm,
              ),
              child: content,
            ),
    );
  }
}

class SendMessageIntent extends Intent {
  const SendMessageIntent();
}

class NewlineInComposerIntent extends Intent {
  const NewlineInComposerIntent();
}

class _ReplyQuoteBlock extends StatelessWidget {
  final String replyToName;
  final String? replyToContent;
  final VoidCallback? onCancelReply;
  final bool useCommuneStyle;
  final bool isDark;

  const _ReplyQuoteBlock({
    required this.replyToName,
    this.replyToContent,
    this.onCancelReply,
    required this.useCommuneStyle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (useCommuneStyle) {
      final brightness = Theme.of(context).brightness;
      return Container(
        margin: const EdgeInsets.only(bottom: VSpacing.xs),
        padding: const EdgeInsets.fromLTRB(
          VSpacing.sm,
          VSpacing.xs,
          VSpacing.xs,
          VSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: VCommuneColors.surfaceTertiaryOf(brightness),
          borderRadius: BorderRadius.circular(VRadius.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 3,
              height: 36,
              margin: const EdgeInsets.only(right: VSpacing.sm),
              decoration: BoxDecoration(
                color: VCommuneColors.textLinkOf(brightness),
                borderRadius: BorderRadius.circular(VRadius.xs),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    replyToName,
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.semiBold,
                      color: VCommuneColors.textLinkOf(brightness),
                      height: VLineHeight.label,
                    ),
                  ),
                  if (replyToContent != null && replyToContent!.isNotEmpty)
                    Text(
                      replyToContent!,
                      style: TextStyle(
                        fontSize: VFontSize.labelSm,
                        color: VCommuneColors.textMutedOf(brightness),
                        height: VLineHeight.label,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (onCancelReply != null)
              IconButton(
                icon: const Icon(VIcons.x, size: VIconSize.sm),
                onPressed: onCancelReply,
                color: VCommuneColors.textMutedOf(brightness),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.sm,
        vertical: VSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: VColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: VColors.primary.withValues(alpha: 0.2)),
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
                  style: const TextStyle(
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
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.outline,
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
    );
  }
}
