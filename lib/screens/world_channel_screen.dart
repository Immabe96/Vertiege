import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/message.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../theme/design_system.dart';
import '../utils/date_format.dart';
import '../widgets/profile/cosmetic_avatar.dart';

// ────────────────────────────────────────────────────────────
// Display item types (shared with chat_room_screen logic)
// ────────────────────────────────────────────────────────────

enum _ItemType { dateSeparator, firstInGroup, subsequent }

class _DisplayItem {
  final _ItemType type;
  final ChannelMessage? message;
  final String dateLabel;

  const _DisplayItem({
    required this.type,
    required this.message,
    required this.dateLabel,
  });

  const _DisplayItem.date(this.dateLabel)
      : type = _ItemType.dateSeparator,
        message = null;

  const _DisplayItem.first(this.message)
      : type = _ItemType.firstInGroup,
        dateLabel = '';

  const _DisplayItem.subsequent(this.message)
      : type = _ItemType.subsequent,
        dateLabel = '';
}

// ────────────────────────────────────────────────────────────
// Screen
// ────────────────────────────────────────────────────────────

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

  /// Track which message IDs have already had their entrance animation.
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
      channelId: widget.channelId,
      senderId: resident.id,
      senderName: resident.name,
      senderAvatar: resident.avatarUrl,
      content: content,
    );
    _controller.clear();
    _scrollToBottom();
  }

  // ── Message grouping ─────────────────────────────────────

  List<_DisplayItem> _buildDisplayItems(List<ChannelMessage> messages) {
    if (messages.isEmpty) return [];

    final items = <_DisplayItem>[];
    const groupWindow = 5 * 60 * 1000; // 5 minutes in ms

    String? lastSenderId;
    int? lastSenderTimestamp;
    DateTime? lastDate;

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      final msgDate = DateTime.fromMillisecondsSinceEpoch(msg.createdAt);
      final msgDay = DateTime(msgDate.year, msgDate.month, msgDate.day);

      // Date separator
      if (lastDate == null || msgDay != lastDate) {
        items.add(_DisplayItem.date(_dateLabel(msg.createdAt)));
        lastDate = msgDay;
        lastSenderId = null;
        lastSenderTimestamp = null;
      }

      // Group check: same sender within 5 minutes?
      final sameSender = msg.senderId == lastSenderId;
      final withinWindow = lastSenderTimestamp != null &&
          (msg.createdAt - lastSenderTimestamp).abs() < groupWindow;

      if (sameSender && withinWindow) {
        items.add(_DisplayItem.subsequent(msg));
      } else {
        items.add(_DisplayItem.first(msg));
      }

      lastSenderId = msg.senderId;
      lastSenderTimestamp = msg.createdAt;
    }

    return items;
  }

  String _dateLabel(int ts) {
    if (ts <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(ts);
    return _simpleDateLabel(date);
  }

  String _simpleDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';

    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    if (diff < 7) return weekdays[date.weekday - 1];
    return '${months[date.month - 1]} ${date.day}';
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resident = ref.watch(residentProvider).resident;
    final messages =
        ref.watch(chatProvider).channelMessages[widget.channelId] ?? [];
    final isLoading =
        !ref.watch(chatProvider).channelMessages.containsKey(widget.channelId);

    final displayItems = _buildDisplayItems(messages);

    return Scaffold(
      appBar: AppBar(title: Text('# ${widget.channelName}')),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? _buildEmpty(theme)
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
                              return _buildItem(
                                theme,
                                item,
                                resident?.id ?? '',
                              );
                            },
                          ),
                          if (_showScrollFab)
                            Positioned(
                              right: Spacing.md,
                              bottom: Spacing.sm,
                              child: _ScrollFab(onTap: _scrollToBottom),
                            ),
                        ],
                      ),
          ),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No messages yet',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Be the first to say something in #${widget.channelName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(ThemeData theme, _DisplayItem item, String residentId) {
    switch (item.type) {
      case _ItemType.dateSeparator:
        return _DateSeparator(label: item.dateLabel);
      case _ItemType.firstInGroup:
        return _MessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          showHeader: true,
          animatedMessageIds: _animatedMessageIds,
        );
      case _ItemType.subsequent:
        return _MessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          showHeader: false,
          animatedMessageIds: _animatedMessageIds,
        );
    }
  }

  Widget _buildInputBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.sm + 4,
        Spacing.xs,
        Spacing.sm,
        Spacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Message #${widget.channelName}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RadiusTokens.xl),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: 10,
                ),
                filled: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          IconButton.filled(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Date separator widget
// ────────────────────────────────────────────────────────────

class _DateSeparator extends StatelessWidget {
  final String label;
  const _DateSeparator({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Message bubble with grouping, sender avatar, entrance anim
// ────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final ChannelMessage message;
  final bool isMe;
  final bool showHeader;
  final Set<String> animatedMessageIds;

  const _MessageBubble({
    required this.message,
    required this.isMe,
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
    final theme = Theme.of(context);
    final isMe = widget.isMe;
    final showHeader = widget.showHeader;

    final bubbleColor = isMe
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    // Directional corners:
    // Sent (right):    tl, bl, br rounded — tr squared
    // Received (left): tr, br, bl rounded — tl squared
    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(RadiusTokens.lg),
            bottomLeft: Radius.circular(RadiusTokens.lg),
            bottomRight: Radius.circular(RadiusTokens.lg),
            topRight: Radius.circular(RadiusTokens.xs),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(RadiusTokens.lg),
            bottomRight: Radius.circular(RadiusTokens.lg),
            bottomLeft: Radius.circular(RadiusTokens.lg),
            topLeft: Radius.circular(RadiusTokens.xs),
          );

    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final margin = showHeader
        ? const EdgeInsets.only(bottom: Spacing.sm)
        : const EdgeInsets.only(bottom: 2);

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: margin,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: alignment,
              children: [
                if (showHeader && !isMe) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Use CosmeticAvatar for sender avatar
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
                      Text(
                        widget.message.senderName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm + 2,
                    vertical: Spacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.message.imageUrl != null &&
                          widget.message.imageUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(RadiusTokens.md),
                            child: _ChannelImage(url: widget.message.imageUrl!),
                          ),
                        ),
                      Text(
                        widget.message.content,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isMe
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatTimestamp(widget.message.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isMe
                              ? theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.6)
                              : theme.colorScheme.onSurfaceVariant,
                          fontSize: FontSizes.caption - 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders message images from network URLs or local file paths.
class _ChannelImage extends StatelessWidget {
  final String url;
  const _ChannelImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(url, fit: BoxFit.cover);
    }
    final file = File(url);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return const SizedBox.shrink();
  }
}

// ────────────────────────────────────────────────────────────
// Scroll-to-bottom FAB
// ────────────────────────────────────────────────────────────

class _ScrollFab extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: theme.colorScheme.onSurface,
            size: IconSizes.lg,
          ),
        ),
      ),
    );
  }
}
