import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/channel.dart';
import '../models/message.dart';
import '../services/permission_service.dart';
import '../state/channel_provider.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../state/world_provider.dart';
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
import '../utils/world_foundations.dart';
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
  ConsumerState<WorldChannelScreen> createState() => _WorldChannelScreenState();
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
    final resident = ref.read(residentProvider).resident;
    notifier.loadChannelMessages(widget.channelId, force: true);
    notifier.subscribeToChannel(widget.channelId);
    if (resident != null) {
      notifier.markChannelRead(
        channelId: widget.channelId,
        residentId: resident.id,
      );
    }
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
    ref
        .read(chatProvider.notifier)
        .sendChannelMessage(
          worldId: widget.worldId,
          channelId: widget.channelId,
          senderId: resident.id,
          senderName: resident.name,
          senderAvatar: resident.avatarUrl,
          content: content,
        )
        .catchError((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message.')),
          );
        });
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final messages =
        ref.watch(chatProvider).channelMessages[widget.channelId] ?? [];
    final isLoading = !ref
        .watch(chatProvider)
        .channelMessages
        .containsKey(widget.channelId);

    final pinnedMessages = messages.where((m) => m.isPinned).toList();
    final unpinnedMessages = messages.where((m) => !m.isPinned).toList();
    final displayItems = buildChatDisplayItems(unpinnedMessages);

    // Check if resident can pin messages (Sovereign or Council)
    final sovereignId = ref
        .watch(worldProvider)
        .worlds[widget.worldId]
        ?.sovereignId;
    final canPin =
        resident != null &&
        WorldPermissions.resolveStanding(
              resident,
              widget.worldId,
              sovereignId,
            ).level >=
            7; // Council+

    final activeMembers = messages.map((m) => m.senderId).toSet().length;

    // Check if this is an announcement channel where posting is restricted
    final channel = ref
        .watch(channelProvider)
        .channelsByWorld[widget.worldId]
        ?.where((c) => c.id == widget.channelId)
        .firstOrNull;
    final isAnnouncement = channel?.channelType == ChannelType.announcement;
    final canPostInChannel = !isAnnouncement || canPin;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '# ${widget.channelName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
                ? _buildEmpty(channel)
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: Spacing.sm,
                        ),
                        itemCount:
                            displayItems.length +
                            (pinnedMessages.isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (pinnedMessages.isNotEmpty && index == 0) {
                            return _PinnedMessagesPanel(
                              pinnedMessages: pinnedMessages,
                              residentId: resident?.id ?? '',
                              worldId: widget.worldId,
                              channelName: widget.channelName,
                              canPin: canPin,
                              onTogglePin: (msgId, pin) {
                                ref
                                    .read(chatProvider.notifier)
                                    .togglePin(
                                      channelId: widget.channelId,
                                      messageId: msgId,
                                      isPinned: pin,
                                    );
                              },
                            );
                          }
                          final itemIndex = pinnedMessages.isNotEmpty
                              ? index - 1
                              : index;
                          final item = displayItems[itemIndex];
                          return _buildItem(
                            item,
                            resident?.id ?? '',
                            canPin: canPin,
                          );
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
          if (!canPostInChannel)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.sm,
              ),
              color: AppColors.warning.withValues(alpha: 0.10),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: IconSizes.sm,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      'This announcement channel is read-only for your rank.',
                      style: TextStyle(
                        fontSize: FontSizes.labelSm,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ChatInputBar(
              controller: _controller,
              onSend: _sendMessage,
              hintText: 'Message #${widget.channelName}',
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(WorldChannel? channel) {
    final world = ref.watch(worldProvider).worlds[widget.worldId];
    final foundation = world == null
        ? ''
        : foundationMarkdownForChannel(
            world: world,
            channelName: channel?.name ?? widget.channelName,
          );
    if (foundation.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: _FoundationPanel(
          channelName: channel?.name ?? widget.channelName,
          markdown: foundation,
        ),
      );
    }

    return AppEmptyState(
      title: 'No messages yet',
      description: 'Be the first to say something in #${widget.channelName}',
      icon: Icons.chat,
      variant: EmptyStateVariant.default_,
    );
  }

  Widget _buildItem(
    ChatDisplayItem item,
    String residentId, {
    bool canPin = false,
  }) {
    switch (item.type) {
      case ChatItemType.dateSeparator:
        return ChatDateSeparator(label: item.dateLabel);
      case ChatItemType.firstInGroup:
        return _MessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          isSystem:
              item.message!.senderId == 'system' ||
              item.message!.senderName == 'System',
          showHeader: true,
          canPin: canPin,
          animatedMessageIds: _animatedMessageIds,
          worldId: widget.worldId,
          channelName: widget.channelName,
          onTogglePin: (msgId, pin) {
            ref
                .read(chatProvider.notifier)
                .togglePin(
                  channelId: widget.channelId,
                  messageId: msgId,
                  isPinned: pin,
                );
          },
        );
      case ChatItemType.subsequent:
        return _MessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          isSystem:
              item.message!.senderId == 'system' ||
              item.message!.senderName == 'System',
          showHeader: false,
          canPin: canPin,
          animatedMessageIds: _animatedMessageIds,
          worldId: widget.worldId,
          channelName: widget.channelName,
          onTogglePin: (msgId, pin) {
            ref
                .read(chatProvider.notifier)
                .togglePin(
                  channelId: widget.channelId,
                  messageId: msgId,
                  isPinned: pin,
                );
          },
        );
    }
  }
}

// ────────────────────────────────────────────────────────────
// Channel message bubble (screen-specific styling)
// ────────────────────────────────────────────────────────────

class _FoundationPanel extends StatelessWidget {
  final String channelName;
  final String markdown;

  const _FoundationPanel({required this.channelName, required this.markdown});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(RadiusTokens.md),
                ),
                child: Icon(
                  _iconFor(channelName),
                  color: AppColors.tertiary,
                  size: IconSizes.md,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '# $channelName',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeights.bold,
                      ),
                    ),
                    const Text(
                      'Foundation channel',
                      style: TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: FontSizes.labelSm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          MarkdownBody(
            data: markdown,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeights.bold,
              ),
              h3: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.tertiary,
                fontWeight: FontWeights.semiBold,
              ),
              p: const TextStyle(
                color: AppColors.inkSecondary,
                fontSize: FontSizes.bodyMd,
                height: 1.35,
              ),
              listBullet: const TextStyle(color: AppColors.tertiary),
              strong: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeights.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String name) => switch (name.toLowerCase()) {
    'info' => Icons.info_outline,
    'rules' => Icons.gavel_outlined,
    'roles' => Icons.badge_outlined,
    _ => Icons.description_outlined,
  };
}

class _MessageBubble extends StatefulWidget {
  final ChannelMessage message;
  final bool isMe;
  final bool isSystem;
  final bool showHeader;
  final bool canPin;
  final String worldId;
  final String channelName;
  final Set<String> animatedMessageIds;
  final void Function(String messageId, bool isPinned)? onTogglePin;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isSystem,
    required this.showHeader,
    this.canPin = false,
    required this.worldId,
    required this.channelName,
    required this.animatedMessageIds,
    this.onTogglePin,
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
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.hustler, width: 3)),
        color: AppColors.hustler.withValues(alpha: 0.05),
      ),
      h1: TextStyle(
        fontSize: FontSizes.headlineMd,
        fontWeight: FontWeights.bold,
        color: textColor,
        fontFamily: AppFont.headline,
      ),
      h2: TextStyle(
        fontSize: FontSizes.bodyLg,
        fontWeight: FontWeights.bold,
        color: textColor,
        fontFamily: AppFont.headline,
      ),
      h3: TextStyle(
        fontSize: FontSizes.bodyMd,
        fontWeight: FontWeights.semiBold,
        color: textColor,
        fontFamily: AppFont.headline,
      ),
    );
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
                ? GestureDetector(
                    onLongPress: widget.canPin
                        ? () => _showPinContextMenu(context)
                        : null,
                    child: _buildSentBubble(showHeader),
                  )
                : GestureDetector(
                    onLongPress: widget.canPin
                        ? () => _showPinContextMenu(context)
                        : null,
                    child: _buildReceivedBubble(showHeader),
                  ),
          ),
        ),
      ),
    );
  }

  void _showPinContextMenu(BuildContext context) {
    final isPinned = widget.message.isPinned;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(RadiusTokens.full),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply, color: AppColors.primary),
              title: const Text('Reply in Thread'),
              subtitle: const Text('Start or join a threaded conversation'),
              onTap: () {
                Navigator.pop(context);
                final router = GoRouter.of(context);
                router.push(
                  '/thread/${widget.message.id}',
                  extra: {
                    'message': widget.message,
                    'channelId': widget.message.channelId,
                    'worldId': widget.worldId,
                    'channelName': widget.channelName,
                  },
                );
              },
            ),
            if (widget.canPin)
              ListTile(
                leading: Icon(
                  isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: isPinned ? AppColors.warning : AppColors.primary,
                ),
                title: Text(isPinned ? 'Unpin Message' : 'Pin Message'),
                subtitle: Text(
                  isPinned
                      ? 'Remove this message from pinned notices'
                      : 'Show this message at the top of the channel',
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onTogglePin?.call(widget.message.id, !isPinned);
                },
              ),
          ],
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
        border: Border(left: BorderSide(color: AppColors.hustler, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarkdownBody(
            data: widget.message.content,
            styleSheet: _markdownStyle(textColor: AppColors.ink),
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
              MarkdownBody(
                data: widget.message.content,
                styleSheet: _markdownStyle(textColor: AppColors.onPrimary),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    formatTimestamp(widget.message.createdAt),
                    style: TextStyle(
                      fontSize: FontSizes.labelSm,
                      color: AppColors.onPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                  if (widget.message.threadCount > 0) ...[
                    const SizedBox(width: Spacing.sm),
                    GestureDetector(
                      onTap: _openThread,
                      child: Text(
                        '${widget.message.threadCount} ${widget.message.threadCount == 1 ? 'reply' : 'replies'}',
                        style: TextStyle(
                          fontSize: FontSizes.labelSm,
                          color: AppColors.onPrimary.withValues(alpha: 0.8),
                          fontWeight: FontWeights.semiBold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openThread() {
    GoRouter.of(context).push(
      '/thread/${widget.message.id}',
      extra: {
        'message': widget.message,
        'channelId': widget.message.channelId,
        'worldId': widget.worldId,
        'channelName': widget.channelName,
      },
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
              MarkdownBody(
                data: widget.message.content,
                styleSheet: _markdownStyle(textColor: AppColors.ink),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    formatTimestamp(widget.message.createdAt),
                    style: const TextStyle(
                      fontSize: FontSizes.labelSm,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  if (widget.message.threadCount > 0) ...[
                    const SizedBox(width: Spacing.sm),
                    GestureDetector(
                      onTap: _openThread,
                      child: Text(
                        '${widget.message.threadCount} ${widget.message.threadCount == 1 ? 'reply' : 'replies'}',
                        style: const TextStyle(
                          fontSize: FontSizes.labelSm,
                          color: AppColors.inkSecondary,
                          fontWeight: FontWeights.semiBold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PinnedMessagesPanel extends StatefulWidget {
  final List<ChannelMessage> pinnedMessages;
  final String residentId;
  final String worldId;
  final String channelName;
  final bool canPin;
  final void Function(String messageId, bool isPinned) onTogglePin;

  const _PinnedMessagesPanel({
    required this.pinnedMessages,
    required this.residentId,
    required this.worldId,
    required this.channelName,
    required this.canPin,
    required this.onTogglePin,
  });

  @override
  State<_PinnedMessagesPanel> createState() => _PinnedMessagesPanelState();
}

class _PinnedMessagesPanelState extends State<_PinnedMessagesPanel> {
  bool _expanded = true;
  final Set<String> _animatedIds = {};

  @override
  Widget build(BuildContext context) {
    if (widget.pinnedMessages.isEmpty) return const SizedBox.shrink();

    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.push_pin, size: 14, color: AppColors.tertiary),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(
                    'Pinned (${widget.pinnedMessages.length})',
                    style: const TextStyle(
                      fontSize: FontSizes.labelSm,
                      fontWeight: FontWeights.semiBold,
                      color: AppColors.tertiary,
                      letterSpacing: LetterSpacing.label,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: IconSizes.sm,
                  color: AppColors.inkMuted,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: Spacing.xs),
            ...widget.pinnedMessages.map(
              (msg) => _MessageBubble(
                message: msg,
                isMe: msg.senderId == widget.residentId,
                isSystem:
                    msg.senderId == 'system' || msg.senderName == 'System',
                showHeader: true,
                canPin: widget.canPin,
                worldId: widget.worldId,
                channelName: widget.channelName,
                animatedMessageIds: _animatedIds,
                onTogglePin: widget.onTogglePin,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
