import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/message.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';
import '../utils/date_format.dart';
import '../widgets/core/status_dot.dart';

// ────────────────────────────────────────────────────────────
// Display item types for message grouping + date separators
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

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const ChatRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _showScrollFab = false;
  String? _imagePath;
  bool _showTyping = false;
  Timer? _typingTimer;
  int _previousOtherMessageCount = 0;

  /// Track which message IDs have already been animated so they
  /// don't re-animate on rebuild.
  final Set<String> _animatedMessageIds = {};

  @override
  void initState() {
    super.initState();
    final roomId = widget.roomId;
    final notifier = ref.read(chatProvider.notifier);
    notifier.loadDmMessages(roomId);
    notifier.subscribeToDm(roomId);

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    ref.read(chatProvider.notifier).unsubscribeFromDm(widget.roomId);
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
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: AnimDurations.normal,
      curve: Curves.easeOutCubic,
    );
  }

  // ── Typing indicator ─────────────────────────────────────

  void _checkTypingIndicator(List<ChannelMessage> messages, String residentId) {
    if (_typingTimer?.isActive ?? false) return;
    final others = messages
        .where((m) => m.senderId != residentId)
        .toList();
    if (others.length > _previousOtherMessageCount) {
      _previousOtherMessageCount = others.length;
      setState(() => _showTyping = true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showTyping = false);
      });
    }
  }

  // ── Image picking ────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (result != null) {
      setState(() => _imagePath = result.path);
    }
  }

  void _removeImage() {
    setState(() => _imagePath = null);
  }

  // ── Send ─────────────────────────────────────────────────

  void _send() {
    final content = _controller.text.trim();
    if (content.isEmpty && _imagePath == null) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    HapticFeedback.lightImpact();
    ref.read(chatProvider.notifier).sendDmMessage(
      roomId: widget.roomId,
      senderId: resident.id,
      senderName: resident.name,
      senderAvatar: resident.avatarUrl,
      content: content,
      imageUrl: _imagePath,
    );
    _controller.clear();
    setState(() => _imagePath = null);
    _scrollToBottom();
  }

  // ── Message grouping ─────────────────────────────────────

  List<_DisplayItem> _buildDisplayItems(
    List<ChannelMessage> messages,
    String residentId,
  ) {
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
        lastSenderId = null; // reset grouping on new day
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
    final chatState = ref.watch(chatProvider);
    final messages = chatState.dmMessages[widget.roomId] ?? [];

    if (resident != null && messages.isNotEmpty) {
      _checkTypingIndicator(messages, resident.id);
    }

    final room = chatState.dmRooms.cast<Map<String, dynamic>?>().firstWhere(
      (r) => r?['id'] == widget.roomId,
      orElse: () => null,
    );
    final recipientName = _recipientName(room, resident?.id ?? '');
    final recipientAvatar = _recipientAvatar(room);

    final displayItems = _buildDisplayItems(messages, resident?.id ?? '');

    return Scaffold(
      appBar: _buildAppBar(theme, recipientName, recipientAvatar),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmpty(theme)
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: Spacing.sm,
                        ),
                        itemCount: displayItems.length + (_showTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_showTyping && index == displayItems.length) {
                            return const _TypingIndicator();
                          }
                          final item = displayItems[index];
                          return _buildItem(theme, item, resident?.id ?? '');
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
          if (_imagePath != null)
            _ImagePreview(path: _imagePath!, onRemove: _removeImage),
          _buildInputBar(theme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    String recipientName,
    String? recipientAvatar,
  ) {
    return AppBar(
      titleSpacing: 4,
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage:
                recipientAvatar != null ? NetworkImage(recipientAvatar) : null,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: recipientAvatar == null
                ? Text(
                    recipientName.isNotEmpty
                        ? recipientName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: FontSizes.body,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: Spacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recipientName.isNotEmpty ? recipientName : 'Chat',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StatusDot(
                    presence: Presence.online,
                    size: 6,
                    borderWidth: 1,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Online',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.online,
                      fontSize: FontSizes.caption - 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            'No messages yet',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            'Send a message to start the conversation',
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
        Spacing.sm,
        Spacing.xs,
        Spacing.xs,
        Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.image_outlined),
            onPressed: _pickImage,
            tooltip: 'Attach image',
            color: theme.colorScheme.onSurfaceVariant,
            iconSize: IconSizes.lg,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Message...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          const SizedBox(width: Spacing.xs),
          IconButton(
            icon: const Icon(Icons.send_rounded),
            onPressed: _send,
            color: theme.colorScheme.primary,
            iconSize: IconSizes.lg,
          ),
        ],
      ),
    );
  }

  // ── Room helpers ─────────────────────────────────────────

  String _recipientName(Map<String, dynamic>? room, String currentId) {
    if (room == null) return '';
    final ids = (room['resident_ids'] as List?)?.cast<String>() ?? [];
    final otherId = ids.firstWhere(
      (id) => id != currentId,
      orElse: () => ids.isNotEmpty ? ids.first : '',
    );
    if (otherId.isEmpty) return '';

    final names = room['names'] as Map<String, dynamic>?;
    if (names != null && names[otherId] is String) {
      return names[otherId] as String;
    }
    final direct = room['other_name'];
    if (direct is String && direct.isNotEmpty) return direct;
    return otherId;
  }

  String? _recipientAvatar(Map<String, dynamic>? room) {
    if (room == null) return null;
    final avatar = room['other_avatar'];
    if (avatar is String && avatar.isNotEmpty) return avatar;
    return null;
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
// Message bubble
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
      // Already animated — show immediately
      _animController.value = 1.0;
    } else {
      widget.animatedMessageIds.add(widget.message.id);
      // Slight delay so the spring is visible
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
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: widget.message.senderAvatar != null
                            ? NetworkImage(widget.message.senderAvatar!)
                            : null,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: widget.message.senderAvatar == null
                            ? Text(
                                widget.message.senderName.isNotEmpty
                                    ? widget.message.senderName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: FontSizes.caption,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
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
                    crossAxisAlignment: alignment,
                    children: [
                      if (widget.message.imageUrl != null &&
                          widget.message.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(RadiusTokens.md),
                          child: _MessageImage(url: widget.message.imageUrl!),
                        ),
                      if (widget.message.content.isNotEmpty) ...[
                        if (widget.message.imageUrl != null &&
                            widget.message.imageUrl!.isNotEmpty)
                          const SizedBox(height: 4),
                        Text(
                          widget.message.content,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isMe
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
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

/// Handles both network URLs and local file paths for message images.
class _MessageImage extends StatelessWidget {
  final String url;
  const _MessageImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(url, fit: BoxFit.cover);
    }
    // Assume local file path
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

// ────────────────────────────────────────────────────────────
// Typing indicator (3 bouncing dots)
// ────────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: Spacing.lg,
        top: Spacing.xs,
        bottom: Spacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm + 4,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(RadiusTokens.lg),
                bottomRight: Radius.circular(RadiusTokens.lg),
                bottomLeft: Radius.circular(RadiusTokens.lg),
                topLeft: Radius.circular(RadiusTokens.xs),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final delay = i * 0.15;
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) {
                    final t = (_ctrl.value + delay) % 1.0;
                    final bounce = math.sin(t * math.pi);
                    return Transform.translate(
                      offset: Offset(0, -4 * bounce),
                      child: Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.3 + 0.4 * bounce),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Image preview before sending
// ────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _ImagePreview({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(path);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.xs,
        Spacing.xs,
        0,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
            child: Image.file(
              file,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.broken_image,
                size: 32,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Image ready to send',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: IconSizes.md),
            onPressed: onRemove,
            tooltip: 'Remove image',
          ),
        ],
      ),
    );
  }
}
