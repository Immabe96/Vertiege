import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/message.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';
import '../widgets/chat/chat_date_separator.dart';
import '../widgets/chat/chat_image.dart';
import '../widgets/chat/chat_input_bar.dart';
import '../widgets/chat/chat_message_grouper.dart';
import '../widgets/chat/scroll_fab.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/core/loading_state.dart';
import '../utils/date_format.dart';
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
          duration: AnimDurations.normal,
          curve: Curves.easeOutCubic,
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
        );
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final messages =
        ref.watch(chatProvider).channelMessages[widget.parentMessage.id] ?? [];
    final isLoading = !ref
        .watch(chatProvider)
        .channelMessages
        .containsKey(widget.parentMessage.id);
    final displayItems = buildChatDisplayItems(messages);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thread',
              style: GoogleFonts.spaceGrotesk(
                fontSize: FontSizes.headlineMd,
                fontWeight: FontWeights.bold,
                color: AppColors.ink,
              ),
            ),
            Text(
              '# ${widget.channelName}',
              style: const TextStyle(
                fontSize: FontSizes.labelSm,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Parent message pinned at top
          _ParentMessageCard(
            message: widget.parentMessage,
            residentId: resident?.id ?? '',
          ),
          Expanded(
            child: isLoading
                ? const GlassLoadingList(itemCount: 5)
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
                          horizontal: Spacing.sm,
                          vertical: Spacing.sm,
                        ),
                        itemCount: displayItems.length,
                        itemBuilder: (context, index) {
                          final item = displayItems[index];
                          return _buildItem(item, resident?.id ?? '');
                        },
                      ),
                      if (_showScrollFab)
                        Positioned(
                          right: Spacing.md,
                          bottom: Spacing.sm,
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
    final isMe = message.senderId == residentId;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
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
                  const SizedBox(width: Spacing.xs),
                  LuminaryNameplate(
                    name: message.senderName,
                    tier: 1,
                    fontSize: FontSizes.labelSm,
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
                  color: isMe ? AppColors.primary : AppColors.glassBackground,
                  borderRadius: isMe
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(RadiusTokens.xl),
                          topRight: Radius.circular(RadiusTokens.xl),
                          bottomLeft: Radius.circular(RadiusTokens.xl),
                          bottomRight: Radius.circular(RadiusTokens.sm),
                        )
                      : const BorderRadius.only(
                          topLeft: Radius.circular(RadiusTokens.xl),
                          topRight: Radius.circular(RadiusTokens.xl),
                          bottomRight: Radius.circular(RadiusTokens.xl),
                          bottomLeft: Radius.circular(RadiusTokens.sm),
                        ),
                  border: isMe
                      ? null
                      : Border.all(color: AppColors.glassBorder),
                ),
                child: MarkdownBody(
                  data: message.content,
                  styleSheet: _markdownStyle(
                    textColor: isMe ? AppColors.onPrimary : AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatTimestamp(message.createdAt),
                style: const TextStyle(
                  fontSize: FontSizes.labelSm,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static MarkdownStyleSheet _markdownStyle({required Color textColor}) {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: FontSizes.bodyMd,
        color: textColor,
        height: LineHeight.body,
      ),
      code: TextStyle(
        fontSize: FontSizes.bodyMd - 2,
        color: AppColors.ink,
        backgroundColor: AppColors.surface,
        fontFamily: AppFont.mono,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      a: const TextStyle(
        fontSize: FontSizes.bodyMd,
        color: AppColors.primary,
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
    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.md),
      borderRadius: BorderRadius.zero,
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
              const SizedBox(width: Spacing.sm),
              LuminaryNameplate(
                name: message.senderName,
                tier: 1,
                fontSize: FontSizes.bodyMd,
              ),
              const Spacer(),
              Text(
                formatTimestamp(message.createdAt),
                style: const TextStyle(
                  fontSize: FontSizes.labelSm,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          MarkdownBody(
            data: message.content,
            styleSheet: _markdownStyle(textColor: AppColors.ink),
          ),
          if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.sm),
              child: ChatImage(url: message.imageUrl!),
            ),
          const SizedBox(height: Spacing.xs),
          Text(
            '${message.threadCount} ${message.threadCount == 1 ? 'reply' : 'replies'}',
            style: const TextStyle(
              fontSize: FontSizes.labelSm,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  static MarkdownStyleSheet _markdownStyle({required Color textColor}) {
    return MarkdownStyleSheet(
      p: TextStyle(
        fontSize: FontSizes.bodyMd,
        color: textColor,
        height: LineHeight.body,
      ),
      code: TextStyle(
        fontSize: FontSizes.bodyMd - 2,
        color: AppColors.ink,
        backgroundColor: AppColors.surface,
        fontFamily: AppFont.mono,
      ),
      a: const TextStyle(
        fontSize: FontSizes.bodyMd,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
      ),
    );
  }
}
