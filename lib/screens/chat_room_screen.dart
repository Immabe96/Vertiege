import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/message.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';
import '../utils/date_format.dart';
import '../widgets/chat/chat_date_separator.dart';
import '../widgets/chat/chat_image.dart';
import '../widgets/chat/chat_input_bar.dart';
import '../widgets/chat/chat_message_grouper.dart';
import '../widgets/chat/scroll_fab.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/core/status_dot.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/profile/luminary_nameplate.dart';

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

  void _checkTypingIndicator(List<ChannelMessage> messages, String residentId) {
    if (_typingTimer?.isActive ?? false) return;
    final others = messages.where((m) => m.senderId != residentId).toList();
    if (others.length > _previousOtherMessageCount) {
      _previousOtherMessageCount = others.length;
      setState(() => _showTyping = true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showTyping = false);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (result != null) {
      setState(() => _imagePath = result.path);
    }
  }

  void _removeImage() {
    setState(() => _imagePath = null);
  }

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

    final displayItems = buildChatDisplayItems(messages);

    return Scaffold(
      appBar: _buildAppBar(theme, recipientName, recipientAvatar),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmpty()
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
                          child: ChatScrollFab(onTap: _scrollToBottom),
                        ),
                    ],
                  ),
          ),
          if (_imagePath != null)
            _ImagePreview(path: _imagePath!, onRemove: _removeImage),
          ChatInputBar(
            controller: _controller,
            onSend: _send,
            showAttach: true,
            onAttach: _pickImage,
          ),
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
          CosmeticAvatar(imageUrl: recipientAvatar, size: 32),
          const SizedBox(width: Spacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recipientName.isNotEmpty ? recipientName : 'Chat',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeights.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StatusDot(presence: Presence.online, size: 6, borderWidth: 1),
                  const SizedBox(width: 4),
                  Text(
                    'Online',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.semanticSuccess,
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

  Widget _buildEmpty() {
    return const AppEmptyState(
      title: 'No messages yet',
      description: 'Send a message to start the conversation',
      icon: Icons.chat_bubble_outline,
      variant: EmptyStateVariant.default_,
    );
  }

  Widget _buildItem(ThemeData theme, ChatDisplayItem item, String residentId) {
    switch (item.type) {
      case ChatItemType.dateSeparator:
        return ChatDateSeparator(label: item.dateLabel);
      case ChatItemType.firstInGroup:
        return _MessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          showHeader: true,
          animatedMessageIds: _animatedMessageIds,
        );
      case ChatItemType.subsequent:
        return _MessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          showHeader: false,
          animatedMessageIds: _animatedMessageIds,
        );
    }
  }

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
// DM message bubble (screen-specific glass styling)
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

  static MarkdownStyleSheet _markdownStyle({required Color textColor}) {
    return MarkdownStyleSheet(
      p: TextStyle(fontSize: FontSizes.bodyMd, color: textColor, height: LineHeight.body),
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
      h1: TextStyle(fontSize: FontSizes.headlineMd, fontWeight: FontWeights.bold, color: textColor, fontFamily: AppFont.headline),
      h2: TextStyle(fontSize: FontSizes.bodyLg, fontWeight: FontWeights.bold, color: textColor, fontFamily: AppFont.headline),
      h3: TextStyle(fontSize: FontSizes.bodyMd, fontWeight: FontWeights.semiBold, color: textColor, fontFamily: AppFont.headline),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMe = widget.isMe;
    final showHeader = widget.showHeader;

    final bubbleColor = isMe
        ? AppColors.primaryContainer.withValues(alpha: 0.55)
        : AppColors.glassBackground;

    final bubbleBorder = isMe
        ? AppColors.primary.withValues(alpha: 0.2)
        : AppColors.glassBorder;

    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(RadiusTokens.cardFeatured),
            bottomLeft: Radius.circular(RadiusTokens.cardFeatured),
            bottomRight: Radius.circular(RadiusTokens.cardFeatured),
            topRight: Radius.circular(RadiusTokens.chip),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(RadiusTokens.cardFeatured),
            bottomRight: Radius.circular(RadiusTokens.cardFeatured),
            bottomLeft: Radius.circular(RadiusTokens.cardFeatured),
            topLeft: Radius.circular(RadiusTokens.chip),
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
                      CosmeticAvatar(
                        imageUrl: widget.message.senderAvatar,
                        size: 24,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm + 2,
                    vertical: Spacing.xs + 2,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: borderRadius,
                    border: Border.all(color: bubbleBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: alignment,
                    children: [
                      if (widget.message.imageUrl != null &&
                          widget.message.imageUrl!.isNotEmpty)
                        ChatImage(url: widget.message.imageUrl!),
                      if (widget.message.content.isNotEmpty) ...[
                        if (widget.message.imageUrl != null &&
                            widget.message.imageUrl!.isNotEmpty)
                          const SizedBox(height: 4),
                        MarkdownBody(
                          data: widget.message.content,
                          styleSheet: _markdownStyle(
                            textColor: isMe
                                ? AppColors.onPrimaryContainer
                                : AppColors.ink,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        formatTimestamp(widget.message.createdAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isMe
                              ? AppColors.onPrimaryContainer.withValues(alpha: 0.6)
                              : AppColors.inkMuted,
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

// ────────────────────────────────────────────────────────────
// Typing indicator (screen-specific)
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
              color: AppColors.glassBackground,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(RadiusTokens.cardFeatured),
                bottomRight: Radius.circular(RadiusTokens.cardFeatured),
                bottomLeft: Radius.circular(RadiusTokens.cardFeatured),
                topLeft: Radius.circular(RadiusTokens.chip),
              ),
              border: Border.all(color: AppColors.glassBorder),
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
                          color: AppColors.inkMuted
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
// Image preview (screen-specific)
// ────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _ImagePreview({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, Spacing.xs, 0),
      borderRadius: BorderRadius.zero,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(RadiusTokens.input),
            child: Image.file(
              file,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(
                Icons.broken_image,
                size: 32,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              'Image ready to send',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.inkMuted,
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
