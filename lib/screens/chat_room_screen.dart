import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
import 'package:image_picker/image_picker.dart';

import '../services/chat_density_prefs.dart';
import '../state/chat_density_provider.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_commune_chat_theme.dart';
import '../theme/v_tokens.dart';
import '../utils/chat_new_since_visit.dart';
import '../utils/presence_utils.dart';
import '../services/chat_notification_scope.dart';
import '../services/supabase.dart';
import '../widgets/chat/chat_connection_banner.dart';
import '../widgets/chat/chat_date_separator.dart';
import '../widgets/chat/chat_input_bar.dart';
import '../widgets/chat/v_message_bubble.dart';
import '../widgets/chat/chat_message_grouper.dart';
import '../widgets/chat/new_since_visit_divider.dart';
import '../widgets/core/v_accessible.dart';
import '../widgets/chat/achievement_share_picker.dart';
import '../widgets/chat/scroll_fab.dart';
import '../widgets/chat/v_achievement_attachment.dart';
import '../widgets/profile/cosmetic_avatar.dart';
import '../widgets/core/status_dot.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/v_feedback.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  final Presence? initialPresence;
  final String? initialDraft;

  const ChatRoomScreen({
    super.key,
    required this.roomId,
    this.initialPresence,
    this.initialDraft,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final _scrollFabTracker = ChatScrollFabTracker();
  bool _loadingOlderRequested = false;
  String? _imagePath;
  Timer? _outboundTypingDebounce;

  final Set<String> _animatedMessageIds = {};
  Presence? _headerPresence;
  DateTime? _visitDividerAnchor;

  String? _replyToMessageId;
  String? _replyToSenderId;
  String? _replyToSenderName;
  String? _replyToContent;

  @override
  void initState() {
    super.initState();
    final roomId = widget.roomId;
    final notifier = ref.read(chatProvider.notifier);
    _visitDividerAnchor = ref.read(chatProvider).channelReads[roomId];
    notifier.loadDmMessages(roomId, force: true);
    notifier.subscribeToDm(roomId);
    notifier.subscribeToTyping(roomId);
    ChatNotificationScope.setActiveDmRoom(roomId);

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resident = ref.read(residentProvider).resident;
      if (resident != null) {
        notifier.markChannelRead(channelId: roomId, residentId: resident.id);
      }
      final draft = widget.initialDraft?.trim();
      if (draft != null && draft.isNotEmpty && _controller.text.isEmpty) {
        _controller.text = draft;
      }
    });
    _headerPresence = widget.initialPresence;
    unawaited(_refreshRecipientPresence());
  }

  Future<void> _refreshRecipientPresence() async {
    final resident = ref.read(residentProvider).resident;
    final rooms = ref.read(chatProvider).dmRooms;
    final room = rooms.cast<Map<String, dynamic>?>().firstWhere(
      (r) => r?['id'] == widget.roomId,
      orElse: () => null,
    );
    final otherId = _recipientId(room, resident?.id ?? '');
    if (otherId.isEmpty || !isSupabaseConfigured()) return;

    try {
      final row = await getSupabase()
          .from('profiles')
          .select('last_seen_at')
          .eq('id', otherId)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _headerPresence = presenceFromProfileField(row?['last_seen_at']);
      });
    } catch (_) {
      if (!mounted) return;
      if (_headerPresence == null && room != null) {
        setState(() {
          _headerPresence = presenceFromProfileField(
            room['other_last_seen_at'],
          );
        });
      }
    }
  }

  @override
  void deactivate() {
    _outboundTypingDebounce?.cancel();
    final resident = ref.read(residentProvider).resident;
    final notifier = ref.read(chatProvider.notifier);
    if (resident != null) {
      notifier.stopTyping(widget.roomId, resident.id);
    }
    notifier.unsubscribeFromTyping(widget.roomId);
    ChatNotificationScope.setActiveDmRoom(null);
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollFabTracker.updateFromScroll(_scrollController)) {
      setState(() {});
    }
    _maybeLoadOlderMessages(_scrollController.hasClients
        ? _scrollController.offset
        : 0);
  }

  void _maybeLoadOlderMessages(double offset) {
    if (offset > 120 || _loadingOlderRequested) return;

    final chatState = ref.read(chatProvider);
    final roomId = widget.roomId;
    if (chatState.dmLoadingOlder[roomId] == true) return;
    if (chatState.dmHasMore[roomId] != true) return;

    _loadingOlderRequested = true;
    final beforeExtent = _scrollController.position.maxScrollExtent;
    final beforeOffset = _scrollController.offset;

    unawaited(
      ref.read(chatProvider.notifier).loadOlderDmMessages(roomId).whenComplete(
        () {
          if (!mounted) return;
          _loadingOlderRequested = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollController.hasClients || !mounted) return;
            final afterExtent = _scrollController.position.maxScrollExtent;
            final delta = afterExtent - beforeExtent;
            if (delta > 0) {
              _scrollController.jumpTo(beforeOffset + delta);
            }
          });
        },
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: VAnimation.normal,
      curve: VAnimation.standard,
    );
  }

  void _onComposerChanged(String text) {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final notifier = ref.read(chatProvider.notifier);
    if (text.trim().isEmpty) {
      _outboundTypingDebounce?.cancel();
      _outboundTypingDebounce = null;
      notifier.stopTyping(widget.roomId, resident.id);
      return;
    }

    _outboundTypingDebounce?.cancel();
    _outboundTypingDebounce = Timer(const Duration(milliseconds: 350), () {
      notifier.startTyping(widget.roomId, resident.id);
    });
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
        VFeedback.showError(context, 'Failed to pick image. Please try again.');
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

  Future<void> _shareAchievement() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final picked = await pickVerifiedAchievementToShare(context, ref);
    if (picked == null || !mounted) return;

    final note = _controller.text.trim();
    final content = achievementShareContent(picked.id, note: note);
    _controller.clear();
    await ref.read(chatProvider.notifier).sendDmMessage(
      roomId: widget.roomId,
      senderId: resident.id,
      senderName: resident.name,
      senderAvatar: resident.avatarUrl,
      content: content,
    );
    if (mounted) _scrollToBottom();
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty && _imagePath == null) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    HapticFeedback.lightImpact();
    ref.read(chatProvider.notifier).stopTyping(widget.roomId, resident.id);
    try {
      if (_replyToMessageId != null) {
        await ref
            .read(chatProvider.notifier)
            .sendDmReply(
              roomId: widget.roomId,
              senderId: resident.id,
              senderName: resident.name,
              senderAvatar: resident.avatarUrl,
              content: content,
              imageUrl: _imagePath,
              replyToMessageId: _replyToMessageId!,
              replyToSenderId: _replyToSenderId!,
              replyToSenderName: _replyToSenderName!,
              replyToContent: _replyToContent!,
            );
      } else {
        await ref
            .read(chatProvider.notifier)
            .sendDmMessage(
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
        VFeedback.showError(
          context,
          'Failed to send message. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;
    final messages = ref.watch(dmRoomMessagesProvider(widget.roomId));
    final messagesLoadError = ref.watch(
      chatProvider.select((s) => s.messagesLoadErrorFor(widget.roomId)),
    );
    final dmRooms = ref.watch(chatProvider.select((s) => s.dmRooms));
    final loadingOlder = ref.watch(
      chatProvider.select((s) => s.dmLoadingOlder[widget.roomId] ?? false),
    );
    final remoteTyping = ref.watch(
      chatProvider.select(
        (s) => s.typingUsers[widget.roomId] ?? const <String>{},
      ),
    );
    final otherTyping =
        resident != null && remoteTyping.any((id) => id != resident.id);

    final room = dmRooms.cast<Map<String, dynamic>?>().firstWhere(
      (r) => r?['id'] == widget.roomId,
      orElse: () => null,
    );
    final recipientName = _recipientName(room, resident?.id ?? '');
    final recipientAvatar = _recipientAvatar(room);
    final recipientId = _recipientId(room, resident?.id ?? '');
    final recipientPresence =
        _headerPresence ??
        widget.initialPresence ??
        _presenceFromRoom(room, resident?.id ?? '');

    if (_scrollFabTracker.syncMessageCount(messages.length)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    final displayItems = buildChatDisplayItems(messages);
    final chatCompact =
        ref.watch(chatDensityProvider) == ChatMessageDensity.compact;

    final unreadDividerIndex = newSinceVisitDividerDisplayIndex(
      messages: messages,
      lastVisitAt: _visitDividerAnchor,
    );

    return ColoredBox(
      color: VCommuneChatTheme.backgroundColor,
      child: VScaffold(
      header: VNestedHeader(
        prefixes: [
          VAccessibleHeaderAction(
            label: 'Back to messages',
            icon: Icon(VIcons.chevronLeft),
            onPress: () {
              if (context.canPop()) context.pop();
            },
          ),
        ],
        title: _buildHeaderTitle(
          theme,
          isDark,
          recipientName,
          recipientAvatar,
          recipientId,
          recipientPresence,
        ),
      ),
      child: Column(
        children: [
          const ChatConnectionBanner(),
          Expanded(
            child: messagesLoadError != null && messages.isEmpty
                ? AppErrorState(
                    message: messagesLoadError,
                    onRetry: () => ref
                        .read(chatProvider.notifier)
                        .loadDmMessages(widget.roomId, force: true),
                  )
                : messages.isEmpty
                ? _buildEmpty()
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          left: VSpacing.sm,
                          right: VSpacing.sm,
                          top: loadingOlder
                              ? VSpacing.xl + VSpacing.sm
                              : VSpacing.sm,
                          bottom: VSpacing.sm,
                        ),
                        itemCount:
                            displayItems.length +
                            (otherTyping ? 1 : 0) +
                            (unreadDividerIndex != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (unreadDividerIndex != null &&
                              index == unreadDividerIndex) {
                            return const NewSinceVisitDivider();
                          }
                          final adjustedIndex =
                              unreadDividerIndex != null &&
                                  index > unreadDividerIndex
                              ? index - 1
                              : index;
                          if (otherTyping &&
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
                              compact: chatCompact,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      if (loadingOlder)
                        Positioned(
                          top: VSpacing.xs,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                          ),
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
          if (_imagePath != null)
            _ImagePreview(path: _imagePath!, onRemove: _removeImage),
          ChatInputBar(
            controller: _controller,
            onSend: _send,
            onChanged: _onComposerChanged,
            showAttach: true,
            useAttachmentTray: true,
            onAttach: _pickImage,
            onShareAchievement: _shareAchievement,
            replyToName: _replyToSenderName,
            replyToContent: _replyToContent,
            onCancelReply: _cancelReply,
            typingIndicator: otherTyping
                ? '${recipientName.isNotEmpty ? recipientName : 'Someone'} is typing…'
                : null,
            useCommuneStyle: true,
          ),
        ],
      ),
    ),
    );
  }

  Presence _presenceFromRoom(Map<String, dynamic>? room, String currentUserId) {
    if (room == null) return Presence.offline;
    return presenceFromProfileField(room['other_last_seen_at']);
  }

  Widget _buildHeaderTitle(
    ThemeData theme,
    bool isDark,
    String recipientName,
    String? recipientAvatar,
    String? recipientId,
    Presence presence,
  ) {
    return Row(
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
                StatusDot(presence: presence, size: 6, borderWidth: 1),
                const SizedBox(width: VSpacing.xs),
                Text(
                  switch (presence) {
                    Presence.online => 'Online',
                    Presence.idle => 'Idle',
                    Presence.dnd => 'Do not disturb',
                    Presence.offline => 'Offline',
                  },
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: switch (presence) {
                      Presence.online => VColors.success,
                      Presence.idle => VColors.warning,
                      Presence.dnd => VColors.error,
                      Presence.offline =>
                        isDark
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
    String residentId, {
    bool compact = false,
  }) {
    switch (item.type) {
      case ChatItemType.dateSeparator:
        return ChatDateSeparator(
          key: ValueKey('date-${item.dateLabel}'),
          label: item.dateLabel,
        );
      case ChatItemType.firstInGroup:
        return RepaintBoundary(
          key: ValueKey(item.message!.id),
          child: VMessageBubble(
            message: item.message!,
            isMe: item.message!.senderId == residentId,
            showHeader: true,
            animatedMessageIds: _animatedMessageIds,
            mode: VMessageBubbleMode.directMessage,
            compact: compact,
            dmConfig: VDirectMessageBubbleConfig(
              currentUserId: residentId,
              onReply: (msg) => _setReply(
                messageId: msg.id,
                senderId: msg.senderId,
                senderName: msg.senderName,
                content: msg.content,
              ),
              onEdit: (msg, newContent) async {
                await ref
                    .read(chatProvider.notifier)
                    .editMessage(
                      roomId: widget.roomId,
                      messageId: msg.id,
                      newContent: newContent,
                    );
              },
              onDelete: (msg) async {
                await ref
                    .read(chatProvider.notifier)
                    .deleteMessage(roomId: widget.roomId, messageId: msg.id);
              },
              onReaction: (msg, emoji) async {
                await ref
                    .read(chatProvider.notifier)
                    .toggleReaction(
                      roomId: widget.roomId,
                      messageId: msg.id,
                      userId: residentId,
                      emoji: emoji,
                    );
              },
            ),
          ),
        );
      case ChatItemType.subsequent:
        return RepaintBoundary(
          key: ValueKey(item.message!.id),
          child: VMessageBubble(
            message: item.message!,
            isMe: item.message!.senderId == residentId,
            showHeader: false,
            animatedMessageIds: _animatedMessageIds,
            mode: VMessageBubbleMode.directMessage,
            compact: compact,
            dmConfig: VDirectMessageBubbleConfig(
              currentUserId: residentId,
              onReply: (msg) => _setReply(
                messageId: msg.id,
                senderId: msg.senderId,
                senderName: msg.senderName,
                content: msg.content,
              ),
              onEdit: (msg, newContent) async {
                await ref
                    .read(chatProvider.notifier)
                    .editMessage(
                      roomId: widget.roomId,
                      messageId: msg.id,
                      newContent: newContent,
                    );
              },
              onDelete: (msg) async {
                await ref
                    .read(chatProvider.notifier)
                    .deleteMessage(roomId: widget.roomId, messageId: msg.id);
              },
              onReaction: (msg, emoji) async {
                await ref
                    .read(chatProvider.notifier)
                    .toggleReaction(
                      roomId: widget.roomId,
                      messageId: msg.id,
                      userId: residentId,
                      emoji: emoji,
                    );
              },
            ),
          ),
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
                          color:
                              (isDark
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
