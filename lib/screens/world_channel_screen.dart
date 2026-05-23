import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/channel.dart';
import '../models/message.dart';
import '../services/permission_service.dart';
import '../state/channel_provider.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../state/world_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../ui/icons/v_icons.dart';
import '../utils/chat_new_since_visit.dart';
import '../widgets/chat/chat_date_separator.dart';
import '../widgets/chat/new_since_visit_divider.dart';
import '../widgets/chat/chat_image.dart';
import '../widgets/chat/chat_input_bar.dart';
import '../widgets/chat/chat_message_grouper.dart';
import '../widgets/chat/scroll_fab.dart';
import '../utils/date_format.dart';
import '../utils/world_foundations.dart';
import '../widgets/core/empty_state.dart';
import '../utils/v_motion.dart';
import '../widgets/core/screen_loading.dart';
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
  DateTime? _visitDividerAnchor;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(chatProvider.notifier);
    _visitDividerAnchor =
        ref.read(chatProvider).channelReads[widget.channelId];
    notifier.loadChannelMessages(widget.channelId, force: true);
    notifier.subscribeToChannel(widget.channelId);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final resident = ref.read(residentProvider).resident;
      if (resident == null) return;
      if (!ref.read(chatProvider).channelReads.containsKey(widget.channelId)) {
        await notifier.loadChannelReads(resident.id);
        if (mounted && _visitDividerAnchor == null) {
          setState(() {
            _visitDividerAnchor =
                ref.read(chatProvider).channelReads[widget.channelId];
          });
        }
      }
      if (!mounted) return;
      await notifier.markChannelRead(
        channelId: widget.channelId,
        residentId: resident.id,
      );
    });
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
          duration: context.motionDuration(VAnimation.normal),
          curve: context.motionCurve,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
    final newSinceDividerIndex = newSinceVisitDividerDisplayIndex(
      messages: unpinnedMessages,
      lastVisitAt: _visitDividerAnchor,
    );
    final pinnedHeaderCount = pinnedMessages.isNotEmpty ? 1 : 0;
    final hasNewSinceDivider = newSinceDividerIndex != null;

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
            7;

    final activeMembers = messages.map((m) => m.senderId).toSet().length;

    final channel = ref
        .watch(channelProvider)
        .channelsByWorld[widget.worldId]
        ?.where((c) => c.id == widget.channelId)
        .firstOrNull;
    final isAnnouncement = channel?.channelType == ChannelType.announcement;
    final canPostInChannel = !isAnnouncement || canPin;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor: (isDark ? VColors.surfaceDark : VColors.surface)
            .withValues(alpha: 0.86),
        elevation: 0,
        leading: Semantics(
          label: 'Back to world',
          child: BackButton(
            color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
          ),
        ),
        title: Semantics(
          header: true,
          label: '${widget.channelName} channel, $activeMembers members',
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '# ${widget.channelName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            Text(
              activeMembers == 1 ? '1 member' : '$activeMembers members',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: VFontWeight.regular,
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const ScreenLoading.list()
                : messages.isEmpty
                ? _buildEmpty(channel)
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.sm,
                          vertical: VSpacing.sm,
                        ),
                        itemCount:
                            displayItems.length +
                            pinnedHeaderCount +
                            (hasNewSinceDivider ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (pinnedHeaderCount > 0 && index == 0) {
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
                          var listIndex = index - pinnedHeaderCount;
                          if (hasNewSinceDivider &&
                              listIndex == newSinceDividerIndex) {
                            return const NewSinceVisitDivider();
                          }
                          if (hasNewSinceDivider &&
                              listIndex > newSinceDividerIndex) {
                            listIndex -= 1;
                          }
                          final item = displayItems[listIndex];
                          return _buildItem(
                            item,
                            resident?.id ?? '',
                            canPin: canPin,
                          );
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
          if (!canPostInChannel)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.lg,
                vertical: VSpacing.sm,
              ),
              color: VColors.warning.withValues(alpha: 0.10),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: VIconSize.sm,
                    color: VColors.warning,
                  ),
                  SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Text(
                      'This announcement channel is read-only for your rank.',
                      style: TextStyle(
                        fontSize: VFontSize.labelSm,
                        color: VColors.onSurfaceVariant,
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
    final foundation = channel?.foundationMarkdown.trim().isNotEmpty == true
        ? channel!.foundationMarkdown
        : world == null
        ? ''
        : foundationMarkdownForChannel(
            world: world,
            channelName: channel?.name ?? widget.channelName,
          );
    if (foundation.isNotEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(VSpacing.md),
        child: _FoundationPanel(
          channelName: channel?.name ?? widget.channelName,
          markdown: foundation,
        ),
      );
    }

    return AppEmptyState(
      icon: Icons.chat_bubble_outline,
      title: 'No messages yet',
      description:
          'Be the first to say something in #${widget.channelName}',
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

class _FoundationPanel extends StatelessWidget {
  final String channelName;
  final String markdown;

  const _FoundationPanel({required this.channelName, required this.markdown});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(VSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VColors.tertiary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(VRadius.md),
                ),
                child: Icon(
                  _iconFor(channelName),
                  color: VColors.tertiary,
                  size: VIconSize.md,
                ),
              ),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '# $channelName',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? VColors.onSurfaceDark
                            : VColors.onSurface,
                        fontWeight: VFontWeight.bold,
                      ),
                    ),
                    Text(
                      'Foundation channel',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                        fontSize: VFontSize.labelSm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.lg),
          MarkdownBody(
            data: markdown,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              h2: theme.textTheme.titleLarge?.copyWith(
                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                fontWeight: VFontWeight.bold,
              ),
              h3: theme.textTheme.titleSmall?.copyWith(
                color: VColors.tertiary,
                fontWeight: VFontWeight.semiBold,
              ),
              p: TextStyle(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
                fontSize: VFontSize.bodyMd,
                height: 1.35,
              ),
              listBullet: const TextStyle(color: VColors.tertiary),
              strong: TextStyle(
                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                fontWeight: VFontWeight.bold,
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
        fontSize: VFontSize.bodyMd,
        color: textColor,
        height: VLineHeight.body,
      ),
      code: TextStyle(
        fontSize: VFontSize.bodyMd - 2,
        color: textColor,
        backgroundColor: textColor.withValues(alpha: 0.1),
        fontFamily: 'monospace',
      ),
      codeblockDecoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      a: TextStyle(
        fontSize: VFontSize.bodyMd,
        color: VColors.primary,
        decoration: TextDecoration.underline,
      ),
      blockquoteDecoration: BoxDecoration(
        border: const Border(
          left: BorderSide(color: VColors.primary, width: 3),
        ),
        color: VColors.primary.withValues(alpha: 0.05),
      ),
      h1: TextStyle(
        fontSize: VFontSize.headlineMd,
        fontWeight: VFontWeight.bold,
        color: textColor,
      ),
      h2: TextStyle(
        fontSize: VFontSize.bodyLg,
        fontWeight: VFontWeight.bold,
        color: textColor,
      ),
      h3: TextStyle(
        fontSize: VFontSize.bodyMd,
        fontWeight: VFontWeight.semiBold,
        color: textColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final showHeader = widget.showHeader;
    final isSystem = widget.isSystem;

    final margin = showHeader
        ? const EdgeInsets.only(bottom: VSpacing.sm)
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPinned = widget.message.isPinned;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(VRadius.xl)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(VIcons.arrowLeft, color: VColors.primary),
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
                  color: isPinned ? VColors.warning : VColors.primary,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: VColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: const Border(
          left: BorderSide(color: VColors.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MarkdownBody(
            data: widget.message.content,
            styleSheet: _markdownStyle(
              textColor: isDark ? VColors.onSurfaceDark : VColors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatTimestamp(widget.message.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: VFontSize.labelSm,
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static const _sentRadius = BorderRadius.only(
    topLeft: Radius.circular(VRadius.lg),
    topRight: Radius.circular(VRadius.lg),
    bottomLeft: Radius.circular(VRadius.lg),
    bottomRight: Radius.circular(VRadius.sm),
  );

  Widget _buildSentBubble(bool showHeader) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: const BoxDecoration(
            color: VColors.primary,
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
                styleSheet: _markdownStyle(textColor: VColors.onPrimary),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    formatTimestamp(widget.message.createdAt),
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: VColors.onPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                  if (widget.message.threadCount > 0) ...[
                    const SizedBox(width: VSpacing.sm),
                    GestureDetector(
                      onTap: _openThread,
                      child: Text(
                        '${widget.message.threadCount} ${widget.message.threadCount == 1 ? 'reply' : 'replies'}',
                        style: TextStyle(
                          fontSize: VFontSize.labelSm,
                          color: VColors.onPrimary.withValues(alpha: 0.8),
                          fontWeight: VFontWeight.semiBold,
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
    topRight: Radius.circular(VRadius.lg),
    bottomRight: Radius.circular(VRadius.lg),
    bottomLeft: Radius.circular(VRadius.lg),
    topLeft: Radius.circular(VRadius.sm),
  );

  Widget _buildReceivedBubble(bool showHeader) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              const SizedBox(width: VSpacing.xs),
              LuminaryNameplate(
                name: widget.message.senderName,
                tier: 1,
                fontSize: VFontSize.labelSm,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? VColors.glassBackgroundDark
                : VColors.glassBackground,
            borderRadius: _receivedRadius,
            border: Border.all(
              color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
            ),
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
                styleSheet: _markdownStyle(
                  textColor: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    formatTimestamp(widget.message.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: VFontSize.labelSm,
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                  if (widget.message.threadCount > 0) ...[
                    const SizedBox(width: VSpacing.sm),
                    GestureDetector(
                      onTap: _openThread,
                      child: Text(
                        '${widget.message.threadCount} ${widget.message.threadCount == 1 ? 'reply' : 'replies'}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: VFontSize.labelSm,
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                          fontWeight: VFontWeight.semiBold,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.pinnedMessages.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(VSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                const Icon(Icons.push_pin, size: 14, color: VColors.tertiary),
                const SizedBox(width: VSpacing.xs),
                Expanded(
                  child: Text(
                    'Pinned (${widget.pinnedMessages.length})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.semiBold,
                      color: VColors.tertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: VIconSize.sm,
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: VSpacing.xs),
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
