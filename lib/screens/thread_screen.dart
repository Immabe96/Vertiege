import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../models/message.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/chat/chat_date_separator.dart';
import '../widgets/chat/chat_image.dart';
import '../widgets/chat/chat_input_bar.dart';
import '../widgets/chat/chat_message_grouper.dart';
import '../widgets/chat/scroll_fab.dart';
import '../ui/icons/v_icons.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/v_accessible.dart';
import '../widgets/core/screen_loading.dart';
import '../utils/date_format.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/profile/luminary_nameplate.dart';
import '../widgets/core/v_feedback.dart';

class ThreadScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String worldId;
  final ChannelMessage parentMessage;
  final String channelName;

  const ThreadScreen({
    super.key,
    required this.channelId,
    required this.worldId,
    required this.parentMessage,
    required this.channelName,
  });

  @override
  ConsumerState<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends ConsumerState<ThreadScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _showScrollFab = false;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(chatProvider.notifier);
    notifier.loadThreadMessages(widget.parentMessage.id);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final showFab = (maxExtent - offset) > 200;
    if (showFab != _showScrollFab) {
      setState(() => _showScrollFab = showFab);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: VAnimation.normal,
          curve: VAnimation.standard,
        );
      }
    });
  }

  void _sendReply() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    HapticFeedback.lightImpact();
    ref
        .read(chatProvider.notifier)
        .sendThreadReply(
          channelId: widget.channelId,
          senderId: resident.id,
          senderName: resident.name,
          senderAvatar: resident.avatarUrl,
          worldId: widget.worldId,
          content: content,
          threadId: widget.parentMessage.id,
        )
        .catchError((_) {
          if (!mounted) return;
          VFeedback.showMessage(context, 'Failed to send reply.');
        });
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final messages =
        ref.watch(chatProvider).channelMessages[widget.parentMessage.id] ?? [];
    final threadId = widget.parentMessage.id;
    final chatState = ref.watch(chatProvider);
    final isLoading = !chatState.channelMessages.containsKey(threadId);
    final messagesLoadError = chatState.messagesLoadErrorFor(threadId);
    final displayItems = buildChatDisplayItems(messages);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FScaffold(
      header: FHeader.nested(
        prefixes: [
          VAccessibleHeaderAction(
            label: 'Back to channel',
            icon: const Icon(FIcons.chevronLeft),
            onPress: () {
              if (context.canPop()) context.pop();
            },
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thread',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            Text(
              '# ${widget.channelName}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          _ParentMessageCard(
            message: widget.parentMessage,
            residentId: resident?.id ?? '',
          ),
          Expanded(
            child: isLoading
                ? const ScreenLoading.list()
                : messagesLoadError != null && messages.isEmpty
                ? AppErrorState(
                    message: messagesLoadError,
                    onRetry: () => ref
                        .read(chatProvider.notifier)
                        .loadThreadMessages(threadId),
                  )
                : messages.isEmpty
                ? AppEmptyState(
                    title: 'No replies yet',
                    description: 'Be the first to reply in this thread',
                    icon: Icons.chat_bubble_outline,
                  )
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.sm,
                          vertical: VSpacing.sm,
                        ),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          return _buildItem(item, resident?.id ?? '');
                        },
                      ),
                      if (_showScrollFab)
                        Positioned(
                          right: VSpacing.md,
                          bottom: VSpacing.sm,
                          child: ChatScrollFab(onTap: _scrollToBottom),
                        ),
                    ],
                  ),
          ),
          ChatInputBar(
            controller: _controller,
            onSend: _sendReply,
            hintText: 'Reply in thread...',
          ),
        ],
      ),
    );
  }

  Widget _buildItem(ChatDisplayItem item, String residentId) {
    switch (item.type) {
      case ChatItemType.dateSeparator:
        return ChatDateSeparator(label: item.dateLabel);
      case ChatItemType.firstInGroup:
      case ChatItemType.subsequent:
        return _buildThreadReply(item.message!, residentId);
    }
  }

  Widget _buildThreadReply(ChannelMessage message, String residentId) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMe = message.senderId == residentId;
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.sm),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CosmeticAvatar(
                    imageUrl: message.senderAvatar,
                    seed: message.senderId,
                    size: 20,
                  ),
                  const SizedBox(width: VSpacing.xs),
                  LuminaryNameplate(
                    name: message.senderName,
                    tier: 1,
                    fontSize: VFontSize.labelSm,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? VColors.primary
                      : (isDark
                            ? VColors.surfaceContainerDark
                            : VColors.surfaceContainerLow),
                  borderRadius: isMe
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(VRadius.xl),
                          topRight: Radius.circular(VRadius.xl),
                          bottomLeft: Radius.circular(VRadius.xl),
                          bottomRight: Radius.circular(VRadius.sm),
                        )
                      : const BorderRadius.only(
                          topLeft: Radius.circular(VRadius.xl),
                          topRight: Radius.circular(VRadius.xl),
                          bottomRight: Radius.circular(VRadius.xl),
                          bottomLeft: Radius.circular(VRadius.sm),
                        ),
                  border: isMe
                      ? null
                      : Border.all(
                          color: isDark
                              ? VColors.outlineVariantDark
                              : VColors.outlineVariant,
                        ),
                ),
                child: MarkdownBody(
                  data: message.content,
                  styleSheet: _markdownStyle(
                    textColor: isMe
                        ? VColors.onPrimary
                        : (isDark ? VColors.onSurfaceDark : VColors.onSurface),
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatTimestamp(message.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static MarkdownStyleSheet _markdownStyle({
    required Color textColor,
    required bool isDark,
  }) {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: VFontSize.bodyMd,
        color: textColor,
        height: VLineHeight.body,
      ),
      code: TextStyle(
        fontSize: VFontSize.bodyMd - 2,
        color: textColor,
        backgroundColor: isDark
            ? VColors.surfaceContainerHighDark
            : VColors.surfaceContainerHigh,
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark
            ? VColors.surfaceContainerHighDark
            : VColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      a: TextStyle(
        fontSize: VFontSize.bodyMd,
        color: VColors.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }
}

class _ParentMessageCard extends StatelessWidget {
  final ChannelMessage message;
  final String residentId;

  const _ParentMessageCard({required this.message, required this.residentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? VColors.surfaceContainerDark
            : VColors.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CosmeticAvatar(
                imageUrl: message.senderAvatar,
                seed: message.senderId,
                size: 28,
              ),
              const SizedBox(width: VSpacing.sm),
              LuminaryNameplate(
                name: message.senderName,
                tier: 1,
                fontSize: VFontSize.bodyMd,
              ),
              const Spacer(),
              Text(
                formatTimestamp(message.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          MarkdownBody(
            data: message.content,
            styleSheet: _markdownStyle(
              textColor: isDark ? VColors.onSurfaceDark : VColors.onSurface,
              isDark: isDark,
            ),
          ),
          if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: VSpacing.sm),
              child: ChatImage(url: message.imageUrl!),
            ),
          const SizedBox(height: VSpacing.xs),
          Text(
            '${message.threadCount} ${message.threadCount == 1 ? 'reply' : 'replies'}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static MarkdownStyleSheet _markdownStyle({
    required Color textColor,
    required bool isDark,
  }) {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: VFontSize.bodyMd,
        color: textColor,
        height: VLineHeight.body,
      ),
      code: TextStyle(
        fontSize: VFontSize.bodyMd - 2,
        color: textColor,
        backgroundColor: isDark
            ? VColors.surfaceContainerHighDark
            : VColors.surfaceContainerHigh,
        fontFamily: 'monospace',
      ),
      a: TextStyle(
        fontSize: VFontSize.bodyMd,
        color: VColors.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }
}
