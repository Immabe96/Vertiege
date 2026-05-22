import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/message.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../ui/buttons/v_button.dart';
import '../ui/icons/v_icons.dart';
import '../utils/date_format.dart';
import '../widgets/chat/chat_date_separator.dart';
import '../widgets/chat/chat_image.dart';
import '../widgets/chat/chat_input_bar.dart';
import '../widgets/chat/chat_message_grouper.dart';
import '../widgets/chat/scroll_fab.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/profile/luminary_nameplate.dart';
import '../widgets/core/status_dot.dart';

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

  String? _replyToMessageId;
  String? _replyToSenderId;
  String? _replyToSenderName;
  String? _replyToContent;

  @override
  void initState() {
    super.initState();
    final roomId = widget.roomId;
    final notifier = ref.read(chatProvider.notifier);
    notifier.loadDmMessages(roomId, force: true);
    notifier.subscribeToDm(roomId);

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        notifier.markChannelRead(channelId: roomId, residentId: resident.id);
      }
    });
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
      duration: VAnimation.normal,
      curve: VAnimation.standard,
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
    try {
      final picker = ImagePicker();
      final result = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
      );
      if (!mounted) return;
      if (result != null) {
        setState(() => _imagePath = result.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to pick image. Please try again.'),
            backgroundColor: VColors.error,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() => _imagePath = null);
  }

  void _setReply({
    required String messageId,
    required String senderId,
    required String senderName,
    required String content,
  }) {
    setState(() {
      _replyToMessageId = messageId;
      _replyToSenderId = senderId;
      _replyToSenderName = senderName;
      _replyToContent = content.length > 100
          ? '${content.substring(0, 100)}...'
          : content;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToMessageId = null;
      _replyToSenderId = null;
      _replyToSenderName = null;
      _replyToContent = null;
    });
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _imagePath == null) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    HapticFeedback.lightImpact();
    try {
      if (_replyToMessageId != null) {
        await ref.read(chatProvider.notifier).sendDmReply(
              roomId: widget.roomId,
              senderId: resident.id,
              senderName: resident.name,
              senderAvatar: resident.avatarUrl,
              content: content,
              replyToMessageId: _replyToMessageId!,
              replyToSenderId: _replyToSenderId!,
              replyToSenderName: _replyToSenderName!,
              replyToContent: _replyToContent!,
            );
      } else {
        await ref.read(chatProvider.notifier).sendDmMessage(
              roomId: widget.roomId,
              senderId: resident.id,
              senderName: resident.name,
              senderAvatar: resident.avatarUrl,
              content: content,
              imageUrl: _imagePath,
            );
      }
      if (mounted) {
        _controller.clear();
        setState(() {
          _imagePath = null;
          _replyToMessageId = null;
          _replyToSenderId = null;
          _replyToSenderName = null;
          _replyToContent = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message. Please try again.'),
            backgroundColor: VColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;
    final chatState = ref.watch(chatProvider);
    final messages = chatState.dmMessages[widget.roomId] ?? [];

    if (resident != null && messages.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkTypingIndicator(messages, resident.id);
      });
    }

    final room = chatState.dmRooms.cast<Map<String, dynamic>?>().firstWhere(
      (r) => r?['id'] == widget.roomId,
      orElse: () => null,
    );
    final recipientName = _recipientName(room, resident?.id ?? '');
    final recipientAvatar = _recipientAvatar(room);
    final recipientId = _recipientId(room, resident?.id ?? '');
    final recipientPresence = _presenceFromRoom(room, resident?.id ?? '');

    final displayItems = buildChatDisplayItems(messages);

    final lastReadAt = chatState.channelReads[widget.roomId];
    int? unreadDividerIndex;
    if (lastReadAt != null && messages.isNotEmpty) {
      for (int i = 0; i < messages.length; i++) {
        final msgTime = DateTime.fromMillisecondsSinceEpoch(
          messages[i].createdAt,
        );
        if (msgTime.isAfter(lastReadAt)) {
          unreadDividerIndex = i;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: _buildAppBar(
        theme,
        isDark,
        recipientName,
        recipientAvatar,
        recipientId,
        recipientPresence,
      ),
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
                          horizontal: VSpacing.sm,
                          vertical: VSpacing.sm,
                        ),
                        itemCount: displayItems.length +
                            (_showTyping ? 1 : 0) +
                            (unreadDividerIndex != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (unreadDividerIndex != null &&
                              index == unreadDividerIndex) {
                            return const _UnreadDivider();
                          }
                          final adjustedIndex =
                              unreadDividerIndex != null &&
                                      index > unreadDividerIndex
                                  ? index - 1
                                  : index;
                          if (_showTyping &&
                              adjustedIndex == displayItems.length) {
                            return const _TypingIndicator();
                          }
                          if (adjustedIndex < displayItems.length) {
                            final item = displayItems[adjustedIndex];
                            return _buildItem(
                              theme,
                              isDark,
                              item,
                              resident?.id ?? '',
                            );
                          }
                          return const SizedBox.shrink();
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
          if (_imagePath != null)
            _ImagePreview(path: _imagePath!, onRemove: _removeImage),
          ChatInputBar(
            controller: _controller,
            onSend: _send,
            showAttach: true,
            onAttach: _pickImage,
            replyToName: _replyToSenderName,
            replyToContent: _replyToContent,
            onCancelReply: _cancelReply,
          ),
        ],
      ),
    );
  }

  Presence _presenceFromRoom(
    Map<String, dynamic>? room,
    String currentUserId,
  ) {
    if (room == null) return Presence.offline;
    final otherLastSeen = room['other_last_seen_at'] as int?;
    if (otherLastSeen == null || otherLastSeen == 0) {
      return Presence.offline;
    }
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(otherLastSeen);
    final diff = DateTime.now().difference(lastSeen).inMinutes;
    if (diff < 3) return Presence.online;
    if (diff < 15) return Presence.idle;
    return Presence.offline;
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    bool isDark,
    String recipientName,
    String? recipientAvatar,
    String? recipientId,
    Presence presence,
  ) {
    return AppBar(
      backgroundColor:
          (isDark ? VColors.surfaceDark : VColors.surface).withValues(
            alpha: 0.86,
          ),
      elevation: 0,
      titleSpacing: VSpacing.xs,
      title: Row(
        children: [
          CosmeticAvatar(
            imageUrl: recipientAvatar,
            seed: recipientId ?? recipientName,
            size: 32,
          ),
          const SizedBox(width: VSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                recipientName.isNotEmpty ? recipientName : 'Chat',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusDot(
                    presence: presence,
                    size: 6,
                    borderWidth: 1,
                  ),
                  const SizedBox(width: VSpacing.xs),
                  Text(
                    switch (presence) {
                      Presence.online => 'Online',
                      Presence.idle => 'Idle',
                      Presence.offline => 'Offline',
                    },
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: switch (presence) {
                        Presence.online => VColors.success,
                        Presence.idle => VColors.warning,
                        Presence.offline => isDark
                            ? VColors.onSurfaceVariantDark
                            : VColors.onSurfaceVariant,
                      },
                      fontSize: VFontSize.labelSm,
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: VColors.onSurfaceVariant,
          ),
          const SizedBox(height: VSpacing.md),
          const Text(
            'No messages yet',
            style: TextStyle(fontWeight: VFontWeight.semiBold),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(color: VColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    ThemeData theme,
    bool isDark,
    ChatDisplayItem item,
    String residentId,
  ) {
    switch (item.type) {
      case ChatItemType.dateSeparator:
        return ChatDateSeparator(label: item.dateLabel);
      case ChatItemType.firstInGroup:
        return _MessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          showHeader: true,
          animatedMessageIds: _animatedMessageIds,
          currentUserId: residentId,
          onReply: (msg) => _setReply(
            messageId: msg.id,
            senderId: msg.senderId,
            senderName: msg.senderName,
            content: msg.content,
          ),
          onEdit: (msg, newContent) async {
            await ref.read(chatProvider.notifier).editMessage(
                  roomId: widget.roomId,
                  messageId: msg.id,
                  newContent: newContent,
                );
          },
          onDelete: (msg) async {
            await ref.read(chatProvider.notifier).deleteMessage(
                  roomId: widget.roomId,
                  messageId: msg.id,
                );
          },
          onReaction: (msg, emoji) async {
            await ref.read(chatProvider.notifier).toggleReaction(
                  roomId: widget.roomId,
                  messageId: msg.id,
                  userId: residentId,
                  emoji: emoji,
                );
          },
        );
      case ChatItemType.subsequent:
        return _MessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          showHeader: false,
          animatedMessageIds: _animatedMessageIds,
          currentUserId: residentId,
          onReply: (msg) => _setReply(
            messageId: msg.id,
            senderId: msg.senderId,
            senderName: msg.senderName,
            content: msg.content,
          ),
          onEdit: (msg, newContent) async {
            await ref.read(chatProvider.notifier).editMessage(
                  roomId: widget.roomId,
                  messageId: msg.id,
                  newContent: newContent,
                );
          },
          onDelete: (msg) async {
            await ref.read(chatProvider.notifier).deleteMessage(
                  roomId: widget.roomId,
                  messageId: msg.id,
                );
          },
          onReaction: (msg, emoji) async {
            await ref.read(chatProvider.notifier).toggleReaction(
                  roomId: widget.roomId,
                  messageId: msg.id,
                  userId: residentId,
                  emoji: emoji,
                );
          },
        );
    }
  }

  String _recipientName(Map<String, dynamic>? room, String currentId) {
    if (room == null) return '';
    final otherId = _recipientId(room, currentId);
    if (otherId.isEmpty) return '';

    final names = room['names'] as Map<String, dynamic>?;
    if (names != null && names[otherId] is String) {
      return names[otherId] as String;
    }
    final direct = room['other_name'];
    if (direct is String && direct.isNotEmpty) return direct;
    return otherId;
  }

  String _recipientId(Map<String, dynamic>? room, String currentId) {
    if (room == null) return '';
    final ids = (room['resident_ids'] as List?)?.cast<String>() ?? [];
    return ids.firstWhere(
      (id) => id != currentId,
      orElse: () => ids.isNotEmpty ? ids.first : '',
    );
  }

  String? _recipientAvatar(Map<String, dynamic>? room) {
    if (room == null) return null;
    final avatar = room['other_avatar'];
    if (avatar is String && avatar.isNotEmpty) return avatar;
    return null;
  }
}

class _MessageBubble extends StatefulWidget {
  final ChannelMessage message;
  final bool isMe;
  final bool showHeader;
  final Set<String> animatedMessageIds;
  final String currentUserId;
  final void Function(ChannelMessage) onReply;
  final Future<void> Function(ChannelMessage, String) onEdit;
  final Future<void> Function(ChannelMessage) onDelete;
  final Future<void> Function(ChannelMessage, String) onReaction;

  static const int maxAnimatedIds = 50;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showHeader,
    required this.animatedMessageIds,
    required this.currentUserId,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
    required this.onReaction,
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
      if (widget.animatedMessageIds.length >= _MessageBubble.maxAnimatedIds) {
        final toRemove = widget.animatedMessageIds
            .take(_MessageBubble.maxAnimatedIds ~/ 2)
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


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isMe = widget.isMe;
    final showHeader = widget.showHeader;
    final msg = widget.message;

    final bubbleColor = isMe
        ? VColors.primary
        : (isDark ? VColors.glassBackgroundDark : VColors.glassBackground);

    final bubbleBorder = isMe
        ? Colors.transparent
        : (isDark ? VColors.glassBorderDark : VColors.glassBorder);

    final textColor = isMe ? VColors.onPrimary : (isDark ? VColors.onSurfaceDark : VColors.onSurface);
    final timestampColor = isMe
        ? VColors.onPrimary.withValues(alpha: 0.6)
        : (isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant);

    final borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(VRadius.lg),
            bottomLeft: Radius.circular(VRadius.lg),
            bottomRight: Radius.circular(VRadius.lg),
            topRight: Radius.circular(VRadius.sm),
          )
        : const BorderRadius.only(
            topRight: Radius.circular(VRadius.lg),
            bottomRight: Radius.circular(VRadius.lg),
            bottomLeft: Radius.circular(VRadius.lg),
            topLeft: Radius.circular(VRadius.sm),
          );

    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final margin = showHeader
        ? const EdgeInsets.only(bottom: VSpacing.sm)
        : const EdgeInsets.only(bottom: VSpacing.xs);

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
                        seed: widget.message.senderId,
                        size: 24,
                      ),
                      const SizedBox(width: VSpacing.xs),
                      LuminaryNameplate(
                        name: widget.message.senderName,
                        fontSize: VFontSize.labelSm,
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.xs),
                ],
                GestureDetector(
                  onLongPress: () => _showMessageOptions(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.sm,
                      vertical: VSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: borderRadius,
                      border: Border.all(color: bubbleBorder),
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
                        if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
                          ChatImage(url: msg.imageUrl!),
                        if (msg.content.isNotEmpty) ...[
                          if (msg.imageUrl != null && msg.imageUrl!.isNotEmpty)
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
                              : _ChatContent(
                                  content: msg.content,
                                  textColor: textColor,
                                ),
                        ],
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
                    currentUserId: widget.currentUserId,
                    onAddReaction: () => _showEmojiPicker(context),
                    onToggleReaction: (emoji) =>
                        widget.onReaction(msg, emoji),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    final isMe = widget.isMe;
    final msg = widget.message;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(VSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['👍', '❤️', '😂', '😮', '😢', '🔥']
                    .map(
                      (emoji) => GestureDetector(
                        onTap: () {
                          widget.onReaction(msg, emoji);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(VSpacing.sm),
                          decoration: BoxDecoration(
                            color: isDark
                                ? VColors.surfaceContainerDark
                                : VColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(VRadius.md),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: VFontSize.headlineSm),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(VIcons.arrowLeft),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                widget.onReply(msg);
              },
            ),
            if (isMe) ...[
              ListTile(
                leading: const Icon(VIcons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: VColors.error,
                ),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: VColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  widget.onDelete(msg);
                },
              ),
            ],
          ],
        ),
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
                widget.onEdit(widget.message, newContent);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.md),
          child: Wrap(
            spacing: VSpacing.sm,
            runSpacing: VSpacing.sm,
            children: [
              '👍',
              '❤️',
              '😂',
              '😮',
              '😢',
              '🔥',
              '🎉',
              '👀',
              '💯',
              '🚀',
            ]
                .map(
                  (emoji) => GestureDetector(
                    onTap: () {
                      widget.onReaction(widget.message, emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(VSpacing.sm),
                      decoration: BoxDecoration(
                        color: isDark
                            ? VColors.surfaceContainerDark
                            : VColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(VRadius.md),
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: VFontSize.headlineMd),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ChatContent extends StatelessWidget {
  final String content;
  final Color textColor;

  const _ChatContent({required this.content, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final spans = _parseMentions(content, textColor);
    return RichText(
      text: TextSpan(children: spans, style: TextStyle(color: textColor)),
    );
  }

  List<TextSpan> _parseMentions(String text, Color defaultColor) {
    final spans = <TextSpan>[];
    final mentionRegex = RegExp(r'@(\w+)');
    var lastEnd = 0;

    for (final match in mentionRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(text: text.substring(lastEnd, match.start)),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            color: VColors.primary,
            fontWeight: VFontWeight.semiBold,
            backgroundColor: VColors.primary.withValues(alpha: 0.1),
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              // Could navigate to profile
            },
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }
}

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
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(
        left: VSpacing.lg,
        top: VSpacing.xs,
        bottom: VSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.sm,
              vertical: VSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? VColors.glassBackgroundDark
                  : VColors.glassBackground,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(VRadius.lg),
                bottomRight: Radius.circular(VRadius.lg),
                bottomLeft: Radius.circular(VRadius.lg),
                topLeft: Radius.circular(VRadius.sm),
              ),
              border: Border.all(
                color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
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
                          color: (isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant)
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

class _ImagePreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _ImagePreview({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final file = File(path);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.xs,
        VSpacing.xs,
        0,
      ),
      decoration: BoxDecoration(
        color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
        border: Border(
          bottom: BorderSide(
            color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.md),
            child: Image.file(
              file,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image,
                size: 32,
                color: VColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Text(
              'Image ready to send',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(VIcons.x, size: VIconSize.md),
            onPressed: onRemove,
            tooltip: 'Remove image',
          ),
        ],
      ),
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
                    Text(entry.key, style: const TextStyle(fontSize: VFontSize.bodyMd)),
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

class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.md),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: VColors.error, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.sm),
            child: Text(
              'Unread',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: VFontSize.labelSm,
                fontWeight: VFontWeight.semiBold,
                color: VColors.error,
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: VColors.error, thickness: 1),
          ),
        ],
      ),
    );
  }
}
