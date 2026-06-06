import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../models/channel.dart';
import '../models/message.dart';
import '../services/permission_service.dart';
import '../services/world_activity_service.dart';
import '../services/world_service.dart';
import '../services/chat_density_prefs.dart';
import '../state/channel_provider.dart';
import '../state/chat_density_provider.dart';
import '../state/chat_provider.dart';
import '../state/resident_provider.dart';
import '../state/world_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_commune_chat_theme.dart';
import '../theme/v_commune_colors.dart';
import '../theme/v_tokens.dart';
import '../utils/chat_new_since_visit.dart';
import '../utils/world_resident_count_label.dart';
import '../widgets/chat/chat_date_separator.dart';
import '../widgets/chat/new_since_visit_divider.dart';
import '../config/tiers.dart';
import '../router/search_navigation.dart';
import '../utils/standing_display_color.dart';
import '../widgets/chat/chat_input_bar.dart';
import '../widgets/chat/v_message_bubble.dart';
import '../widgets/chat/v_channel_details_sheet.dart';
import '../widgets/chat/chat_message_grouper.dart';
import '../widgets/chat/scroll_fab.dart';
import '../widgets/chat/v_pin_message_banner.dart';
import '../widgets/chat/v_slash_commands.dart';
import '../widgets/chat/v_media_picker.dart';
import '../widgets/chat/v_member_list_sheet.dart';
import '../widgets/chat/v_achievement_attachment.dart';
import '../widgets/chat/achievement_share_picker.dart';
import '../widgets/worlds/world_constitution_pin.dart';
import '../widgets/voice/campfire_mini_bar.dart';
import '../utils/world_foundations.dart';
import '../widgets/core/empty_state.dart';
import '../utils/v_motion.dart';
import '../services/chat_notification_scope.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/core/v_feedback.dart';
import '../widgets/feed/cross_post_to_feed_sheet.dart';
import '../widgets/chat/channel_mention_suggestions.dart';
import '../utils/text_parser.dart';

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

  final _scrollFabTracker = ChatScrollFabTracker();
  final Set<String> _animatedMessageIds = {};
  DateTime? _visitDividerAnchor;
  bool _didInitialScroll = false;
  Timer? _outboundTypingDebounce;
  int _totalResidents = 0;
  int? _onlineResidents;
  final Set<String> _prefetchedThreads = {};
  final Map<String, int> _memberRepById = {};
  String? _imagePath;
  final _mentionController = ChannelMentionController();
  List<String> _mentionSuggestions = const [];

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(chatProvider.notifier);
    _visitDividerAnchor = ref.read(chatProvider).channelReads[widget.channelId];
    notifier.loadChannelMessages(widget.channelId, force: true);
    notifier.subscribeToChannel(widget.channelId);
    notifier.subscribeToTyping(widget.channelId);
    ChatNotificationScope.setActiveChannel(channelId: widget.channelId);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      unawaited(_loadResidentCounts());
      unawaited(_loadMentionResidents());
      unawaited(WorldActivityService.touchWorld(widget.worldId));
      final resident = ref.read(residentProvider).resident;
      if (resident == null) return;
      if (!ref.read(chatProvider).channelReads.containsKey(widget.channelId)) {
        await notifier.loadChannelReads(resident.id);
        if (mounted && _visitDividerAnchor == null) {
          setState(() {
            _visitDividerAnchor = ref
                .read(chatProvider)
                .channelReads[widget.channelId];
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
  void deactivate() {
    _outboundTypingDebounce?.cancel();
    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      ref
          .read(chatProvider.notifier)
          .stopTyping(widget.channelId, resident.id);
    }
    ref.read(chatProvider.notifier).unsubscribeFromTyping(widget.channelId);
    ref.read(chatProvider.notifier).unsubscribeFromChannel(widget.channelId);
    ChatNotificationScope.clearChannel();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _maybePrefetchThreadPreviews(List<ChannelMessage> messages) {
    final notifier = ref.read(chatProvider.notifier);
    final loaded = ref.read(chatProvider).channelMessages;
    for (final message in messages) {
      if (message.threadCount <= 0) continue;
      if (_prefetchedThreads.contains(message.id)) continue;
      if (loaded.containsKey(message.id)) continue;
      _prefetchedThreads.add(message.id);
      unawaited(notifier.loadThreadMessages(message.id));
    }
  }

  String? _threadPreviewFor(ChannelMessage message) {
    if (message.threadCount <= 0) return null;
    final replies = ref.watch(channelMessagesProvider(message.id));
    if (replies.isEmpty) return null;
    final last = replies.last;
    final snippet = last.content.replaceAll('\n', ' ').trim();
    if (snippet.isEmpty) return '${last.senderName} replied';
    final preview = snippet.length > 72
        ? '${snippet.substring(0, 72)}…'
        : snippet;
    return '${last.senderName}: $preview';
  }

  Future<void> _loadResidentCounts() async {
    final world = ref.read(worldProvider).worlds[widget.worldId];
    final fallbackTotal = world?.memberCount ?? 0;
    try {
      final counts = await WorldService.residentPresenceCounts(widget.worldId);
      final members = await WorldService.getMembers(widget.worldId);
      if (!mounted) return;
      setState(() {
        _totalResidents = counts.total > 0 ? counts.total : fallbackTotal;
        _onlineResidents = counts.online > 0 ? counts.online : null;
        _memberRepById
          ..clear()
          ..addEntries(
            members.map((m) {
              final id = m['resident_id'] as String? ?? '';
              final rep = (m['rep'] as int?) ?? 0;
              return MapEntry(id, rep);
            }).where((e) => e.key.isNotEmpty),
          );
      });
    } catch (_) {
      if (mounted && fallbackTotal > 0) {
        setState(() => _totalResidents = fallbackTotal);
      }
    }
  }

  Color? _senderNameColor(String senderId) {
    final world = ref.read(worldProvider).worlds[widget.worldId];
    final rep = _memberRepById[senderId];
    if (rep == null) return null;
    return standingDisplayColor(
      rep,
      sovereignId: world?.sovereignId,
      residentId: senderId,
    );
  }

  void _handleSlashPin() {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;
    final messages =
        ref.read(chatProvider).channelMessages[widget.channelId] ?? [];
    final mine = messages.where((m) => m.senderId == resident.id).toList();
    if (mine.isEmpty) return;
    final last = mine.last;
    _controller.clear();
    ref.read(chatProvider.notifier).togglePin(
      channelId: widget.channelId,
      messageId: last.id,
      isPinned: !last.isPinned,
    );
  }

  void _handleSlashThread() {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;
    final messages =
        ref.read(chatProvider).channelMessages[widget.channelId] ?? [];
    final mine = messages.where((m) => m.senderId == resident.id).toList();
    if (mine.isEmpty) return;
    _controller.clear();
    final last = mine.last;
    context.push(
      '/thread/${last.id}',
      extra: {
        'message': last,
        'channelId': widget.channelId,
        'worldId': widget.worldId,
        'channelName': widget.channelName,
      },
    );
  }

  void _handleSlashTier() {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;
    _controller.clear();
    final rep = _memberRepById[resident.id] ??
        resident.worldStandings[widget.worldId]?.rep ??
        0;
    final standing = getStanding(rep);
    VFeedback.showMessage(
      context,
      '${standing.title} · $rep rep in this world',
    );
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
          duration: context.motionDuration(VAnimation.normal),
          curve: context.motionCurve,
        );
      }
    });
  }

  void _scrollToNewSinceVisitDivider() {
    if (_didInitialScroll) return;
    if (_visitDividerAnchor == null) return;
    _didInitialScroll = true;
    final all =
        ref.read(chatProvider).channelMessages[widget.channelId] ?? const [];
    final unpinnedMessages = all.where((m) => !m.isPinned).toList();
    if (unpinnedMessages.isEmpty) {
      _didInitialScroll = false;
      return;
    }
    final displayItems = buildChatDisplayItems(unpinnedMessages);
    final dividerIndex = newSinceVisitDividerDisplayIndex(
      messages: unpinnedMessages,
      lastVisitAt: _visitDividerAnchor,
    );
    if (dividerIndex == null || dividerIndex <= 0) return;
    final total = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    if (total <= 0) return;
    final renderedIndex = dividerIndex;
    final perChild = displayItems.isEmpty ? 0.0 : total / displayItems.length;
    final target = (perChild * renderedIndex).clamp(0.0, total).toDouble();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(target);
    });
  }

  Future<void> _loadMentionResidents() async {
    final members = await WorldService.getMembers(widget.worldId);
    _mentionController.setResidents(members);
  }

  void _onComposerChanged(String text) {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final cursor = _controller.selection.baseOffset;
    _mentionController.onTextChanged(text, cursor);
    final suggestions = _mentionController.suggestions;
    if (suggestions != _mentionSuggestions) {
      setState(() => _mentionSuggestions = suggestions);
    }

    final notifier = ref.read(chatProvider.notifier);
    if (text.trim().isEmpty) {
      _outboundTypingDebounce?.cancel();
      _outboundTypingDebounce = null;
      notifier.stopTyping(widget.channelId, resident.id);
      return;
    }

    _outboundTypingDebounce?.cancel();
    _outboundTypingDebounce = Timer(const Duration(milliseconds: 350), () {
      notifier.startTyping(widget.channelId, resident.id);
    });
  }

  void _applyMentionSuggestion(String name) {
    final cursor = _controller.selection.baseOffset;
    final result = _mentionController.applySuggestion(
      _controller.text,
      name,
      cursor,
    );
    if (result == null) return;
    _controller.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.cursor),
    );
    setState(() => _mentionSuggestions = const []);
    _onComposerChanged(result.text);
  }

  Future<void> _shareAchievement() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final picked = await pickVerifiedAchievementToShare(context, ref);
    if (picked == null || !mounted) return;
    final note = _controller.text.trim();
    final content = achievementShareContent(picked.id, note: note);
    _controller.clear();
    await ref.read(chatProvider.notifier).sendChannelMessage(
      worldId: widget.worldId,
      channelId: widget.channelId,
      senderId: resident.id,
      senderName: resident.name,
      senderAvatar: resident.avatarUrl,
      content: content,
    );
    _scrollToBottom();
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
    } catch (_) {
      if (mounted) {
        VFeedback.showError(context, 'Failed to pick image. Please try again.');
      }
    }
  }

  void _removeImage() {
    setState(() => _imagePath = null);
  }

  void _sendMessage() {
    final content = _controller.text.trim();
    if (content.isEmpty && _imagePath == null) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    ref.read(chatProvider.notifier).stopTyping(widget.channelId, resident.id);
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
          imageUrl: _imagePath,
        )
        .catchError((_) {
          if (!mounted) return;
          VFeedback.showMessage(context, 'Failed to send message.');
        });
    _controller.clear();
    setState(() => _imagePath = null);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resident = ref.watch(residentProvider).resident;
    final messages = ref.watch(channelMessagesProvider(widget.channelId));
    final remoteTyping = ref.watch(
      chatProvider.select(
        (s) => s.typingUsers[widget.channelId] ?? const <String>{},
      ),
    );
    final otherTyping =
        resident != null && remoteTyping.any((id) => id != resident.id);
    final messagesLoadError = ref.watch(
      channelMessagesErrorProvider(widget.channelId),
    );
    final isLoading = ref.watch(
      channelMessagesLoadingProvider(widget.channelId),
    );

    final pinnedMessages = messages.where((m) => m.isPinned).toList();
    final unpinnedMessages = messages.where((m) => !m.isPinned).toList();
    _maybePrefetchThreadPreviews(unpinnedMessages);
    if (_scrollFabTracker.syncMessageCount(unpinnedMessages.length)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    if (!_didInitialScroll && messages.isNotEmpty) {
      _scrollToNewSinceVisitDivider();
    }
    final displayItems = buildChatDisplayItems(unpinnedMessages);
    final newSinceDividerIndex = newSinceVisitDividerDisplayIndex(
      messages: unpinnedMessages,
      lastVisitAt: _visitDividerAnchor,
    );
    final hasNewSinceDivider = newSinceDividerIndex != null;
    final composerText = _controller.text;
    final slashFilter = VSlashCommandBar.commandFilter(composerText);

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

    final world =
        ref.watch(worldProvider).worlds[widget.worldId];
    final worldName = world?.name ?? 'World';
    final totalResidents = _totalResidents > 0
        ? _totalResidents
        : (world?.memberCount ?? 0);
    final residentSubtitle = worldChannelResidentSubtitle(
      totalResidents: totalResidents,
      onlineResidents: _onlineResidents,
    );

    final channel = ref
        .watch(channelProvider)
        .channelsByWorld[widget.worldId]
        ?.where((c) => c.id == widget.channelId)
        .firstOrNull;
    final isAnnouncement = channel?.channelType == ChannelType.announcement;
    final canPostInChannel = !isAnnouncement || canPin;
    final chatCompact =
        ref.watch(chatDensityProvider) == ChatMessageDensity.compact;
    final isRulesChannel =
        (channel?.name ?? widget.channelName).toLowerCase() == 'rules';
    final showConstitutionPin = isRulesChannel && world != null;

    return ColoredBox(
      color: VCommuneChatTheme.backgroundColor,
      child: VPage(
      showBack: true,
      title: '',
      titleWidget: Semantics(
        header: true,
        label: '${widget.channelName} channel, $residentSubtitle',
        button: true,
        child: GestureDetector(
          onTap: () => showChannelDetailsSheet(
            context,
            worldId: widget.worldId,
            channelId: widget.channelId,
            channelName: widget.channelName,
            worldName: worldName,
            activeResidentCount: totalResidents,
            pinnedCount: pinnedMessages.length,
          ),
          behavior: HitTestBehavior.opaque,
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
              if (residentSubtitle.isNotEmpty)
                Text(
                  residentSubtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: VFontWeight.regular,
                    color: VCommuneChatTheme.timestampMuted,
                  ),
                ),
            ],
          ),
        ),
      ),
      headerActions: [
        VHeaderAction(
          icon: const Icon(Icons.search),
          onPress: () => openChannelSearch(
            context,
            worldId: widget.worldId,
            channelId: widget.channelId,
            channelName: widget.channelName,
          ),
        ),
        VHeaderAction(
          icon: const Icon(Icons.people_outline),
          onPress: () => showResidentListSheet(
            context,
            worldId: widget.worldId,
            channelName: widget.channelName,
          ),
        ),
      ],
      body: Column(
        children: [
          VPinMessageBanner(
            pinnedMessages: pinnedMessages,
            residentId: resident?.id ?? '',
            worldId: widget.worldId,
            channelName: widget.channelName,
            canPin: canPin,
            onTogglePin: (msgId, pin) {
              ref.read(chatProvider.notifier).togglePin(
                channelId: widget.channelId,
                messageId: msgId,
                isPinned: pin,
              );
            },
          ),
          Expanded(
            child: isLoading
                ? const ScreenLoading.list()
                : messagesLoadError != null && messages.isEmpty
                ? AppErrorState(
                    message: messagesLoadError,
                    onRetry: () => ref
                        .read(chatProvider.notifier)
                        .loadChannelMessages(widget.channelId, force: true),
                  )
                : messages.isEmpty
                ? _buildEmpty(channel)
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        cacheExtent: 480,
                        addAutomaticKeepAlives: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.sm,
                          vertical: VSpacing.sm,
                        ),
                        itemCount:
                            displayItems.length +
                            (hasNewSinceDivider ? 1 : 0) +
                            (showConstitutionPin ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (showConstitutionPin && index == 0) {
                            return WorldConstitutionPin(world: world);
                          }
                          var listIndex =
                              showConstitutionPin ? index - 1 : index;
                          if (hasNewSinceDivider &&
                              listIndex == newSinceDividerIndex) {
                            return const NewSinceVisitDivider();
                          }
                          if (hasNewSinceDivider &&
                              listIndex > newSinceDividerIndex) {
                            listIndex -= 1;
                          }
                          final item = displayItems[listIndex];
                          return RepaintBoundary(
                            key: ValueKey(
                              item.message?.id ?? 'sep-${item.dateLabel}',
                            ),
                            child: _buildItem(
                              item,
                              resident?.id ?? '',
                              canPin: canPin,
                              compact: chatCompact,
                            ),
                          );
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
          else ...[
            const CampfireChannelBar(),
            if (_imagePath != null)
              _ChannelImagePreview(path: _imagePath!, onRemove: _removeImage),
            if (_mentionSuggestions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VSpacing.md,
                  0,
                  VSpacing.md,
                  VSpacing.xs,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ChannelMentionSuggestions(
                    suggestions: _mentionSuggestions,
                    onSelect: _applyMentionSuggestion,
                  ),
                ),
              ),
            ChatInputBar(
              controller: _controller,
              onSend: _sendMessage,
              onChanged: (text) {
                _onComposerChanged(text);
                setState(() {});
              },
              hintText: 'Message #${widget.channelName}',
              typingIndicator: otherTyping ? 'Someone is typing…' : null,
              canSendOverride: _imagePath != null,
              useCommuneStyle: true,
              showAttach: true,
              useAttachmentTray: true,
              onAttach: _pickImage,
              onShareAchievement: _shareAchievement,
              onOpenMediaPicker: () => showVMediaPicker(
                context,
                resident: resident,
                onPick: (asset) {
                  _controller.text = '${_controller.text}$asset'.trim();
                  setState(() {});
                },
              ),
              slashCommandBar: VSlashCommandBar.shouldShow(composerText)
                  ? VSlashCommandBar(
                      filter: slashFilter,
                      commands: VSlashCommandBar.channelCommands(
                        onPin: _handleSlashPin,
                        onThread: _handleSlashThread,
                        onTier: _handleSlashTier,
                      ),
                    )
                  : null,
            ),
          ],
        ],
      ),
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
      description: 'Be the first to say something in #${widget.channelName}',
    );
  }

  Widget _buildItem(
    ChatDisplayItem item,
    String residentId, {
    bool canPin = false,
    bool compact = false,
  }) {
    switch (item.type) {
      case ChatItemType.dateSeparator:
        return ChatDateSeparator(label: item.dateLabel);
      case ChatItemType.firstInGroup:
        return VMessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          showHeader: true,
          animatedMessageIds: _animatedMessageIds,
          mode: VMessageBubbleMode.channel,
          compact: compact,
          threadPreview: _threadPreviewFor(item.message!),
          channelConfig: _channelBubbleConfig(
            item.message!,
            canPin: canPin,
          ),
          onRetryFailed: item.message!.sendFailed
              ? () => ref.read(chatProvider.notifier).retryFailedChannelMessage(
                    worldId: widget.worldId,
                    channelId: widget.channelId,
                    messageId: item.message!.id,
                  )
              : null,
        );
      case ChatItemType.subsequent:
        return VMessageBubble(
          message: item.message!,
          isMe: item.message!.senderId == residentId,
          showHeader: false,
          animatedMessageIds: _animatedMessageIds,
          mode: VMessageBubbleMode.channel,
          compact: compact,
          threadPreview: _threadPreviewFor(item.message!),
          channelConfig: _channelBubbleConfig(
            item.message!,
            canPin: canPin,
          ),
          onRetryFailed: item.message!.sendFailed
              ? () => ref.read(chatProvider.notifier).retryFailedChannelMessage(
                    worldId: widget.worldId,
                    channelId: widget.channelId,
                    messageId: item.message!.id,
                  )
              : null,
        );
    }
  }

  VChannelBubbleConfig _channelBubbleConfig(
    ChannelMessage message, {
    required bool canPin,
  }) {
    final resident = ref.read(residentProvider).resident;
    final selfHandle = resident == null
        ? null
        : TextParser.mentionHandleForName(resident.name);
    final threadUnread = message.hasThread
        ? ref.read(chatProvider.notifier).threadUnreadCount(
              message.id,
              currentUserId: resident?.id,
            )
        : 0;
    return VChannelBubbleConfig(
      isSystem:
          message.senderId == 'system' || message.senderName == 'System',
      canPin: canPin,
      worldId: widget.worldId,
      channelName: widget.channelName,
      currentUserId: resident?.id,
      selfMentionHandle: selfHandle?.isNotEmpty == true ? selfHandle : null,
      threadUnreadCount: threadUnread,
      senderNameColor: _senderNameColor(message.senderId),
      onTogglePin: (msgId, pin) {
        ref.read(chatProvider.notifier).togglePin(
          channelId: widget.channelId,
          messageId: msgId,
          isPinned: pin,
        );
      },
      onReaction: resident == null
          ? null
          : (msg, key) => ref.read(chatProvider.notifier).toggleChannelReaction(
              channelId: widget.channelId,
              messageId: msg.id,
              userId: resident.id,
              emoji: key,
            ),
      onShareToFeed: () => showCrossPostToFeedSheet(
        context,
        message: message,
        sourceWorldId: widget.worldId,
        sourceChannelName: widget.channelName,
      ),
    );
  }
}

class _FoundationPanel extends StatelessWidget {
  final String channelName;
  final String markdown;

  const _FoundationPanel({required this.channelName, required this.markdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VSpacing.lg),
      decoration: BoxDecoration(
        color: VCommuneColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(VRadius.lg),
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
                      style: const TextStyle(
                        color: VCommuneColors.headerPrimary,
                        fontSize: VFontSize.headlineSm,
                        fontWeight: VFontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Foundation channel',
                      style: TextStyle(
                        color: VCommuneColors.textMuted,
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
              h2: const TextStyle(
                color: VCommuneColors.headerPrimary,
                fontSize: VFontSize.headlineMd,
                fontWeight: VFontWeight.bold,
              ),
              h3: TextStyle(
                color: VColors.tertiary,
                fontSize: VFontSize.bodyLg,
                fontWeight: VFontWeight.semiBold,
              ),
              p: const TextStyle(
                color: VCommuneColors.textMuted,
                fontSize: VFontSize.bodyMd,
                height: 1.35,
              ),
              listBullet: const TextStyle(color: VColors.tertiary),
              strong: const TextStyle(
                color: VCommuneColors.headerPrimary,
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

class _ChannelImagePreview extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _ChannelImagePreview({required this.path, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
              File(path),
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
            icon: const Icon(Icons.close, size: VIconSize.md),
            onPressed: onRemove,
            tooltip: 'Remove image',
          ),
        ],
      ),
    );
  }
}

