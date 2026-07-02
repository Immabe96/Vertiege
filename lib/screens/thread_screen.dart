import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../models/message.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_commune_chat_theme.dart';
import '../theme/v_tokens.dart';
import '../utils/date_format.dart';
import '../widgets/chat/chat_date_separator.dart';
import '../widgets/chat/chat_image.dart';
import '../widgets/chat/chat_input_bar.dart';
import '../widgets/chat/chat_message_grouper.dart';
import '../widgets/chat/scroll_fab.dart';
import '../widgets/chat/v_message_bubble.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/v_accessible.dart';
import '../widgets/core/screen_loading.dart';
import '../services/chat_notification_scope.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/profile/luminary_nameplate.dart';

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
  final _scrollFabTracker = ChatScrollFabTracker();
  final Set<String> _animatedMessageIds = {};

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(chatProvider.notifier);
    notifier.loadThreadMessages(widget.parentMessage.id);
    notifier.subscribeToTyping(widget.channelId);
    ChatNotificationScope.setActiveChannel(
      channelId: widget.channelId,
      threadId: widget.parentMessage.id,
    );
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final residentId = ref.read(residentProvider).resident?.id;
      if (residentId != null) {
        ref.read(chatProvider.notifier).markThreadRead(
              threadId: widget.parentMessage.id,
              currentUserId: residentId,
            );
      }
    });
  }

  @override
  void deactivate() {
    ref.read(chatProvider.notifier).unsubscribeFromTyping(widget.channelId);
    super.deactivate();
  }

  @override
  void dispose() {
    ChatNotificationScope.clearChannel();
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollFabTracker.updateFromScroll(_scrollController)) {
      setState(() {});
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
    final threadId = widget.parentMessage.id;
    ref.listen(
      chatProvider.select((s) => s.channelMessages[threadId]?.length ?? 0),
      (previous, next) {
        final residentId = ref.read(residentProvider).resident?.id;
        if (residentId == null || next == (previous ?? 0)) return;
        ref.read(chatProvider.notifier).markThreadRead(
              threadId: threadId,
              currentUserId: residentId,
            );
      },
    );
    final messages =
        ref.watch(chatProvider).channelMessages[threadId] ?? [];
    final chatState = ref.watch(chatProvider);
    final isLoading = !chatState.channelMessages.containsKey(threadId);
    final messagesLoadError = chatState.messagesLoadErrorFor(threadId);
    final remoteTyping = ref.watch(
      chatProvider.select(
        (s) => s.typingUsers[widget.channelId] ?? const <String>{},
      ),
    );
    final otherTyping =
        resident != null && remoteTyping.any((id) => id != resident.id);
    if (_scrollFabTracker.syncMessageCount(messages.length)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    final displayItems = buildChatDisplayItems(messages);
    final theme = Theme.of(context);

    return ColoredBox(
      color: VCommuneChatTheme.backgroundColor,
      child: VScaffold(
      header: VNestedHeader(
        prefixes: [
          VAccessibleHeaderAction(
            label: 'Back to channel',
            icon: const Icon(VIcons.chevronLeft),
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
                color: VCommuneChatTheme.timestampMuted,
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
                ? const AppEmptyState(
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
                      if (_scrollFabTracker.show)
                        Positioned(
                          right: VSpacing.md,
                          bottom: VSpacing.sm,
                          child: ChatScrollFab(
                            onTap: _scrollToBottom,
                            badgeCount: _scrollFabTracker.badgeCount,
                          ),
                        ),
                    ],
                  ),
          ),
          ChatInputBar(
            controller: _controller,
            onSend: _sendReply,
            hintText: 'Reply in thread...',
            typingIndicator: otherTyping ? 'Someone is typing…' : null,
            useCommuneStyle: true,
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildItem(ChatDisplayItem item, String residentId) {
    switch (item.type) {
      case ChatItemType.dateSeparator:
        return ChatDateSeparator(label: item.dateLabel);
      case ChatItemType.firstInGroup:
      case ChatItemType.subsequent:
        return VMessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          showHeader: item.type == ChatItemType.firstInGroup,
          animatedMessageIds: _animatedMessageIds,
          mode: VMessageBubbleMode.channel,
          channelConfig: VChannelBubbleConfig(
            worldId: widget.worldId,
            channelName: widget.channelName,
            currentUserId: residentId,
            onReaction: (msg, emoji) async {
              ref.read(chatProvider.notifier).toggleThreadReaction(
                    threadId: widget.parentMessage.id,
                    messageId: msg.id,
                    userId: residentId,
                    emoji: emoji,
                  );
            },
          ),
        );
    }
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
            color: Theme.of(context).colorScheme.outlineVariant,
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
                fontSize: VFontSize.bodyMd,
              ),
              const Spacer(),
              Text(
                formatTimestamp(message.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          MarkdownBody(
            data: message.content,
            styleSheet: _markdownStyle(
              context: context,
              textColor: Theme.of(context).colorScheme.onSurface,
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle({
    required BuildContext context,
    required Color textColor,
    required bool isDark,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
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
        color: colorScheme.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }
}
