import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../../models/message.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_chat_theme.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../theme/v_animation.dart';
import '../../utils/date_format.dart';
import '../profile/cosmetic_avatar.dart';
import '../profile/luminary_nameplate.dart';
import 'chat_image.dart';
import 'v_link_embed.dart';
import 'v_message_actions.dart';
import 'v_message_content.dart';
import 'v_achievement_attachment.dart';
import 'v_chat_badge_reactions.dart';
import 'v_message_reaction_picker.dart';
import 'v_system_message.dart';
import 'v_thread_indicator_chip.dart';

/// Channel vs direct-message bubble behavior.
enum VMessageBubbleMode { channel, directMessage }

/// Channel-specific bubble configuration (threads, pins, markdown).
final class VChannelBubbleConfig {
  final bool isSystem;
  final bool canPin;
  final String worldId;
  final String channelName;
  final String? currentUserId;
  final void Function(String messageId, bool isPinned)? onTogglePin;
  final Future<void> Function(ChannelMessage message, String reactionKey)?
  onReaction;
  final Color? senderNameColor;

  const VChannelBubbleConfig({
    this.isSystem = false,
    this.canPin = false,
    required this.worldId,
    required this.channelName,
    this.currentUserId,
    this.onTogglePin,
    this.onReaction,
    this.senderNameColor,
  });
}

/// DM-specific bubble configuration (replies, reactions, edit/delete).
final class VDirectMessageBubbleConfig {
  final String currentUserId;
  final void Function(ChannelMessage) onReply;
  final Future<void> Function(ChannelMessage, String) onEdit;
  final Future<void> Function(ChannelMessage) onDelete;
  final Future<void> Function(ChannelMessage, String) onReaction;

  const VDirectMessageBubbleConfig({
    required this.currentUserId,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReaction,
  });
}

/// Shared commune message bubble for world channels and DMs.
class VMessageBubble extends StatefulWidget {
  final ChannelMessage message;
  final bool isMe;
  final bool showHeader;
  final Set<String> animatedMessageIds;
  final VMessageBubbleMode mode;
  final VChannelBubbleConfig? channelConfig;
  final VDirectMessageBubbleConfig? dmConfig;
  final bool compact;
  final String? threadPreview;
  final VoidCallback? onRetryFailed;

  static const int maxAnimatedIds = 50;

  const VMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showHeader,
    required this.animatedMessageIds,
    required this.mode,
    this.channelConfig,
    this.dmConfig,
    this.compact = false,
    this.threadPreview,
    this.onRetryFailed,
  }) : assert(
         (mode == VMessageBubbleMode.channel && channelConfig != null) ||
             (mode == VMessageBubbleMode.directMessage && dmConfig != null),
       );

  @override
  State<VMessageBubble> createState() => _VMessageBubbleState();
}

class _VMessageBubbleState extends State<VMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _hasAnimated = false;

  bool get _isChannel => widget.mode == VMessageBubbleMode.channel;

  VChannelBubbleConfig get _channel => widget.channelConfig!;

  VDirectMessageBubbleConfig get _dm => widget.dmConfig!;

  bool get _isSystem => _isChannel && _channel.isSystem;

  @override
  void initState() {
    super.initState();
    _hasAnimated = widget.animatedMessageIds.contains(widget.message.id);

    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    _animController = AnimationController(
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 350),
      vsync: this,
    );

    _opacity = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _slide = Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    if (_hasAnimated) {
      _animController.value = 1.0;
    } else {
      if (!_isChannel &&
          widget.animatedMessageIds.length >= VMessageBubble.maxAnimatedIds) {
        final toRemove = widget.animatedMessageIds
            .take(VMessageBubble.maxAnimatedIds ~/ 2)
            .toList();
        widget.animatedMessageIds.removeAll(toRemove);
      }
      widget.animatedMessageIds.add(widget.message.id);
      Future.delayed(const Duration(milliseconds: 30), () {
        if (mounted) _animController.forward();
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _incomingAuthorHeader({
    required String? imageUrl,
    required String seed,
    required String name,
    int tier = 1,
    bool showAvatar = true,
    Color? nameColor,
  }) {
    return Row(
      children: [
        if (showAvatar) ...[
          CosmeticAvatar(
            imageUrl: imageUrl,
            seed: seed,
            size: 24,
          ),
          const SizedBox(width: VSpacing.xs),
        ],
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: nameColor != null
                    ? Text(
                        name,
                        style: TextStyle(
                          fontSize: VFontSize.labelSm,
                          fontWeight: VFontWeight.semiBold,
                          color: nameColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : LuminaryNameplate(
                        name: name,
                        tier: tier,
                        fontSize: VFontSize.labelSm,
                      ),
              ),
              const SizedBox(width: VSpacing.sm),
              Text(
                formatTimestamp(widget.message.createdAt),
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  color: VCommuneChatTheme.timestampMutedOf(
                    Theme.of(context).brightness,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final showHeader = widget.showHeader;
    final compact = widget.compact;

    final margin = showHeader
        ? EdgeInsets.only(bottom: compact ? VSpacing.xs : VSpacing.sm)
        : EdgeInsets.only(
            bottom: compact ? 1 : (_isChannel ? 2 : VSpacing.xs),
          );

    final bubble = Align(
      alignment: _isSystem
          ? Alignment.center
          : isMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: margin,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: _isSystem
            ? VSystemMessage(content: widget.message.content)
            : _isChannel
            ? _buildChannelBubble(showHeader, isMe)
            : _buildDmBubble(context, showHeader, isMe),
      ),
    );

    final animated = context.motionEnabled
        ? FadeTransition(
            opacity: _opacity,
            child: SlideTransition(position: _slide, child: bubble),
          )
        : bubble;

    Widget child = animated;
    if (widget.message.sendFailed &&
        widget.isMe &&
        widget.onRetryFailed != null) {
      child = GestureDetector(
        onTap: widget.onRetryFailed,
        child: Column(
          crossAxisAlignment: widget.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            animated,
            const Padding(
              padding: EdgeInsets.only(top: VSpacing.xs),
              child: Text(
                'Failed to send · tap to retry',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  color: VColors.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RepaintBoundary(
      key: ValueKey(widget.message.id),
      child: child,
    );
  }

  Widget _buildChannelBubble(bool showHeader, bool isMe) {
    return GestureDetector(
      onLongPress: () => _showChannelMessageOptions(context),
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -300) {
          _openThread();
        }
      },
      child: isMe
          ? _buildChannelSentBubble()
          : _buildChannelReceivedBubble(showHeader),
    );
  }

  Widget _buildDmBubble(BuildContext context, bool showHeader, bool isMe) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final msg = widget.message;
    final compact = widget.compact;

    final bubbleColor = isMe
        ? VCommuneChatTheme.sentBubbleColor
        : VCommuneChatTheme.receivedBubbleColorOf(brightness);

    final textColor = isMe
        ? VCommuneChatTheme.sentTextColor
        : VCommuneChatTheme.receivedTextColorOf(brightness);
    final timestampColor = isMe
        ? VCommuneChatTheme.sentTextColor.withValues(alpha: 0.6)
        : VCommuneChatTheme.timestampMutedOf(brightness);

    final borderRadius = isMe
        ? VCommuneChatTheme.sentBorderRadius
        : VCommuneChatTheme.receivedBorderRadius;

    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (showHeader && !isMe) ...[
          _incomingAuthorHeader(
            imageUrl: widget.message.senderAvatar,
            seed: widget.message.senderId,
            name: widget.message.senderName,
          ),
          SizedBox(height: compact ? 2 : VSpacing.xs),
        ],
        GestureDetector(
          onLongPress: () => _showDmMessageOptions(context),
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -300) {
              _dm.onReply(msg);
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: compact ? VSpacing.xs : VSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
            ),
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                if (msg.hasReply) ...[
                  _ReplyPreview(
                    senderName: msg.replyToSenderName ?? 'Unknown',
                    content: msg.replyToContent ?? '',
                    isMe: isMe,
                    textColor: textColor,
                  ),
                  const SizedBox(height: VSpacing.xs),
                ],
                if (_dmImageUrls(msg).isNotEmpty)
                  ChatImageGrid(urls: _dmImageUrls(msg)),
                if (msg.content.isNotEmpty) ...[
                  if (_dmImageUrls(msg).isNotEmpty)
                    const SizedBox(height: VSpacing.xs),
                  msg.isDeleted
                      ? Text(
                          msg.content,
                          style: TextStyle(
                            fontSize: VFontSize.bodyMd,
                            color: timestampColor,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      : VMessageContent(
                          content: msg.content,
                          textColor: textColor,
                        ),
                ],
                VLinkEmbed.forMessageContent(msg.content) ??
                    const SizedBox.shrink(),
                if (!showHeader || isMe)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatTimestamp(msg.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: timestampColor,
                          fontSize: VFontSize.labelSm,
                        ),
                      ),
                      if (msg.isEdited) ...[
                        const SizedBox(width: VSpacing.xs),
                        Text(
                          '(edited)',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: timestampColor,
                            fontSize: VFontSize.labelSm,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (msg.hasReactions)
          _ReactionBar(
            reactions: msg.reactions,
            currentUserId: _dm.currentUserId,
            onAddReaction: () => _showEmojiPicker(context),
            onToggleReaction: (emoji) => _dm.onReaction(msg, emoji),
          ),
      ],
    );
  }

  List<String> _dmImageUrls(ChannelMessage msg) =>
      imageUrlsForMessage(imageUrl: msg.imageUrl, content: msg.content);

  List<String> _channelImageUrls() => imageUrlsForMessage(
    imageUrl: widget.message.imageUrl,
    content: widget.message.content,
  );

  Widget _buildMessageMedia(Color textColor) {
    final urls = _channelImageUrls();
    final achId = achievementIdFromMessageContent(widget.message.content);
    final bodyText = achId != null
        ? messageTextWithoutAchievementMarker(widget.message.content)
        : widget.message.content;
    final embed = achId == null
        ? VLinkEmbed.forMessageContent(widget.message.content)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (achId != null) ...[
          VAchievementAttachment(
            achievementId: achId,
            trailingText: bodyText.isNotEmpty ? bodyText : null,
          ),
          const SizedBox(height: VSpacing.xs),
        ],
        if (urls.isNotEmpty) ...[
          ChatImageGrid(urls: urls),
          const SizedBox(height: VSpacing.xs),
        ],
        if (bodyText.isNotEmpty && achId == null)
          VMessageContent(content: bodyText, textColor: textColor),
        if (embed != null) embed,
      ],
    );
  }

  Widget _buildChannelReactions() {
    final userId = _channel.currentUserId;
    final onReaction = _channel.onReaction;
    if (userId == null || onReaction == null) return const SizedBox.shrink();
    if (!widget.message.hasReactions) return const SizedBox.shrink();

    return VChatBadgeReactions(
      reactions: widget.message.reactions,
      currentUserId: userId,
      onToggle: (key) => onReaction(widget.message, key),
    );
  }

  Widget _buildChannelSentBubble() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.md + VSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: VCommuneChatTheme.sentBubbleColor,
            borderRadius: VCommuneChatTheme.sentBorderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMessageMedia(VCommuneChatTheme.sentTextColor),
              const SizedBox(height: 2),
              Text(
                formatTimestamp(widget.message.createdAt),
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  color: VCommuneChatTheme.sentTextColor.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildChannelReactions(),
        VThreadIndicatorChip(
          replyCount: widget.message.threadCount,
          previewText: widget.threadPreview,
          onTap: _openThread,
        ),
      ],
    );
  }

  void _showChannelMessageOptions(BuildContext context) {
    if (_isSystem) return;
    final userId = _channel.currentUserId;
    final onReaction = _channel.onReaction;
    showVSheet(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onReaction != null && userId != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VSpacing.md,
                VSpacing.sm,
                VSpacing.md,
                VSpacing.xs,
              ),
              child: Row(
                children: kDefaultReactionEmojis
                    .take(6)
                    .map(
                      (emoji) => Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            onReaction(widget.message, emoji);
                          },
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('React with achievement'),
              onTap: () {
                Navigator.pop(context);
                showChatBadgeReactionPicker(
                  context,
                  onPick: (key) => onReaction(widget.message, key),
                );
              },
            ),
            Divider(
              color: VCommuneColors.dividerOf(
                Theme.of(context).brightness,
              ),
              height: 1,
            ),
          ],
          ...buildChannelMessageActions(
            context: context,
            message: widget.message,
            canPin: _channel.canPin,
            onOpenThread: _openThread,
            onTogglePin: (pin) =>
                _channel.onTogglePin?.call(widget.message.id, pin),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
      maxSize: 0.5,
    );
  }

  void _openThread() {
    GoRouter.of(context).push(
      '/thread/${widget.message.id}',
      extra: {
        'message': widget.message,
        'channelId': widget.message.channelId,
        'worldId': _channel.worldId,
        'channelName': _channel.channelName,
      },
    );
  }

  Widget _buildChannelReceivedBubble(bool showHeader) {
    final brightness = Theme.of(context).brightness;
    final compact = widget.compact;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          _incomingAuthorHeader(
            imageUrl: widget.message.senderAvatar,
            seed: widget.message.senderId,
            name: widget.message.senderName,
            tier: 1,
            nameColor: _channel.senderNameColor,
          ),
          SizedBox(height: compact ? 2 : 4),
        ],
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: compact ? VSpacing.sm : VSpacing.md + VSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: VCommuneChatTheme.receivedBubbleColorOf(brightness),
            borderRadius: VCommuneChatTheme.receivedBorderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMessageMedia(
                VCommuneChatTheme.receivedTextColorOf(brightness),
              ),
              if (!showHeader) ...[
                const SizedBox(height: 2),
                Text(
                  formatTimestamp(widget.message.createdAt),
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: VCommuneChatTheme.timestampMutedOf(brightness),
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildChannelReactions(),
        VThreadIndicatorChip(
          replyCount: widget.message.threadCount,
          previewText: widget.threadPreview,
          onTap: _openThread,
        ),
      ],
    );
  }

  void _showDmMessageOptions(BuildContext context) {
    final isMe = widget.isMe;
    final msg = widget.message;

    showMessageActionSheet(
      context,
      onReaction: (emoji) => _dm.onReaction(msg, emoji),
      actions: buildDmMessageActions(
        context: context,
        message: msg,
        isMe: isMe,
        onReply: () => _dm.onReply(msg),
        onEdit: () => _showEditDialog(context),
        onDelete: () => _dm.onDelete(msg),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.message.content);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: isDark
                ? VColors.surfaceContainerDark
                : VColors.surfaceContainer,
          ),
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Save',
            onPressed: () {
              final newContent = controller.text.trim();
              if (newContent.isNotEmpty) {
                _dm.onEdit(widget.message, newContent);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    showMessageReactionPicker(
      context,
      onPick: (emoji) => _dm.onReaction(widget.message, emoji),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final String senderName;
  final String content;
  final bool isMe;
  final Color textColor;

  const _ReplyPreview({
    required this.senderName,
    required this.content,
    required this.isMe,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.xs,
        vertical: VSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VRadius.sm),
        border: Border(
          left: BorderSide(
            color: isMe ? textColor.withValues(alpha: 0.4) : VColors.primary,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: TextStyle(
              fontSize: VFontSize.labelSm,
              fontWeight: VFontWeight.semiBold,
              color: isMe ? textColor.withValues(alpha: 0.7) : VColors.primary,
            ),
          ),
          Text(
            content,
            style: TextStyle(
              fontSize: VFontSize.labelSm,
              color: textColor.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ReactionBar extends StatelessWidget {
  final Map<String, List<String>> reactions;
  final String currentUserId;
  final VoidCallback onAddReaction;
  final void Function(String emoji) onToggleReaction;

  const _ReactionBar({
    required this.reactions,
    required this.currentUserId,
    required this.onAddReaction,
    required this.onToggleReaction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: VSpacing.xs),
      child: Wrap(
        spacing: VSpacing.xs,
        runSpacing: VSpacing.xs,
        children: [
          ...reactions.entries.map((entry) {
            final hasReacted = entry.value.contains(currentUserId);
            return GestureDetector(
              onTap: () => onToggleReaction(entry.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VSpacing.xs,
                  vertical: VSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: hasReacted
                      ? VColors.primary.withValues(alpha: 0.15)
                      : (isDark
                            ? VColors.surfaceContainerDark
                            : VColors.surfaceContainer),
                  borderRadius: BorderRadius.circular(VRadius.pill),
                  border: Border.all(
                    color: hasReacted
                        ? VColors.primary.withValues(alpha: 0.3)
                        : (isDark
                              ? VColors.outlineVariantDark
                              : VColors.outlineVariant),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontSize: VFontSize.bodyMd),
                    ),
                    if (entry.value.length > 1) ...[
                      const SizedBox(width: VSpacing.xs),
                      Text(
                        '${entry.value.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: hasReacted
                              ? VColors.primary
                              : (isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          GestureDetector(
            onTap: onAddReaction,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.xs,
                vertical: VSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? VColors.surfaceContainerDark
                    : VColors.surfaceContainer,
                borderRadius: BorderRadius.circular(VRadius.pill),
                border: Border.all(
                  color: isDark
                      ? VColors.outlineVariantDark
                      : VColors.outlineVariant,
                ),
              ),
              child: const Icon(
                Icons.add,
                size: 14,
                color: VColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
