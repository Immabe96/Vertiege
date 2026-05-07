import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/core/loading_state.dart';
import '../utils/date_format.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/profile/luminary_nameplate.dart';

class WorldChannelScreen extends ConsumerStatefulWidget {
  final String worldId;
  final String channelId;
  final String channelName;

  const WorldChannelScreen({
    super.key,
    required this.worldId,
    required this.channelId,
    required this.channelName,
  });

  @override
  ConsumerState<WorldChannelScreen> createState() =>
      _WorldChannelScreenState();
}

class _WorldChannelScreenState extends ConsumerState<WorldChannelScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _showScrollFab = false;
  final Set<String> _animatedMessageIds = {};

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(chatProvider.notifier);
    notifier.loadChannelMessages(widget.channelId);
    notifier.subscribeToChannel(widget.channelId);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    ref.read(chatProvider.notifier).unsubscribeFromChannel(widget.channelId);
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

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    HapticFeedback.lightImpact();
    ref.read(chatProvider.notifier).sendChannelMessage(
      worldId: widget.worldId,
      channelId: widget.channelId,
      senderId: resident.id,
      senderName: resident.name,
      senderAvatar: resident.avatarUrl,
      content: content,
    );
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final messages =
        ref.watch(chatProvider).channelMessages[widget.channelId] ?? [];
    final isLoading =
        !ref.watch(chatProvider).channelMessages.containsKey(widget.channelId);

    final displayItems = buildChatDisplayItems(messages);

    final activeMembers = messages.map((m) => m.senderId).toSet().length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '# ${widget.channelName}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: FontSizes.headlineMd,
                fontWeight: FontWeights.bold,
                color: AppColors.ink,
              ),
            ),
            Text(
              activeMembers == 1 ? '1 member' : '$activeMembers members',
              style: const TextStyle(
                fontSize: FontSizes.labelSm,
                fontWeight: FontWeights.regular,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const GlassLoadingList(itemCount: 8)
                : messages.isEmpty
                    ? _buildEmpty()
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
                              child: ChatScrollFab(
                                onTap: _scrollToBottom,
                                backgroundColor: AppColors.surfaceContainerHigh,
                              ),
                            ),
                        ],
                      ),
          ),
          ChatInputBar(
            controller: _controller,
            onSend: _sendMessage,
            hintText: 'Message #${widget.channelName}',
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return AppEmptyState(
      title: 'No messages yet',
      description: 'Be the first to say something in #${widget.channelName}',
      icon: Icons.chat,
      variant: EmptyStateVariant.default_,
    );
  }

  Widget _buildItem(ChatDisplayItem item, String residentId) {
    switch (item.type) {
      case ChatItemType.dateSeparator:
        return ChatDateSeparator(label: item.dateLabel);
      case ChatItemType.firstInGroup:
        return _MessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          isSystem: item.message!.senderId == 'system' ||
              item.message!.senderName == 'System',
          showHeader: true,
          animatedMessageIds: _animatedMessageIds,
        );
      case ChatItemType.subsequent:
        return _MessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          isSystem: item.message!.senderId == 'system' ||
              item.message!.senderName == 'System',
          showHeader: false,
          animatedMessageIds: _animatedMessageIds,
        );
    }
  }
}

// ────────────────────────────────────────────────────────────
// Channel message bubble (screen-specific styling)
// ────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final ChannelMessage message;
  final bool isMe;
  final bool isSystem;
  final bool showHeader;
  final Set<String> animatedMessageIds;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isSystem,
    required this.showHeader,
    required this.animatedMessageIds,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _hasAnimated = false;

  @override
  void initState() {
    super.initState();
    _hasAnimated = widget.animatedMessageIds.contains(widget.message.id);

    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _slide = Tween(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    ));

    if (_hasAnimated) {
      _animController.value = 1.0;
    } else {
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

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final showHeader = widget.showHeader;
    final isSystem = widget.isSystem;

    final margin = showHeader
        ? const EdgeInsets.only(bottom: Spacing.sm)
        : const EdgeInsets.only(bottom: 2);

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: isSystem
              ? Alignment.center
              : isMe
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
          child: Container(
            margin: margin,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: isSystem
                ? _buildSystemBubble()
                : isMe
                    ? _buildSentBubble(showHeader)
                    : _buildReceivedBubble(showHeader),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemBubble() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.hustler.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border(
          left: BorderSide(color: AppColors.hustler, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message.content,
            style: const TextStyle(
              fontSize: FontSizes.bodyMd,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatTimestamp(widget.message.createdAt),
            style: const TextStyle(
              fontSize: FontSizes.labelSm,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  static const _sentRadius = BorderRadius.only(
    topLeft: Radius.circular(RadiusTokens.xl),
    topRight: Radius.circular(RadiusTokens.xl),
    bottomLeft: Radius.circular(RadiusTokens.xl),
    bottomRight: Radius.circular(RadiusTokens.sm),
  );

  Widget _buildSentBubble(bool showHeader) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: _sentRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.message.imageUrl != null &&
                  widget.message.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ChatImage(url: widget.message.imageUrl!),
                ),
              Text(
                widget.message.content,
                style: const TextStyle(
                  fontSize: FontSizes.bodyMd,
                  color: AppColors.onPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatTimestamp(widget.message.createdAt),
                style: TextStyle(
                  fontSize: FontSizes.labelSm,
                  color: AppColors.onPrimary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _receivedRadius = BorderRadius.only(
    topLeft: Radius.circular(RadiusTokens.xl),
    topRight: Radius.circular(RadiusTokens.xl),
    bottomRight: Radius.circular(RadiusTokens.xl),
    bottomLeft: Radius.circular(RadiusTokens.sm),
  );

  Widget _buildReceivedBubble(bool showHeader) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CosmeticAvatar(
                  totalXp: 0,
                  size: 24,
                  imageUrl: widget.message.senderAvatar,
                ),
              ),
              const SizedBox(width: Spacing.xs),
              LuminaryNameplate(
                name: widget.message.senderName,
                tier: 1,
                fontSize: FontSizes.labelSm,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: _receivedRadius,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.message.imageUrl != null &&
                  widget.message.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: ChatImage(url: widget.message.imageUrl!),
                ),
              Text(
                widget.message.content,
                style: const TextStyle(
                  fontSize: FontSizes.bodyMd,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatTimestamp(widget.message.createdAt),
                style: const TextStyle(
                  fontSize: FontSizes.labelSm,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
