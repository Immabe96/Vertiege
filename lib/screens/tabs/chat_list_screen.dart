import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../../models/channel.dart';
import '../../router/search_navigation.dart';
import '../../router/world_navigation.dart';
import '../../models/world.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../services/world_channel_access_service.dart';
import '../../services/world_mute_prefs.dart';
import '../../services/dm_room_mute_prefs.dart';
import '../../services/world_service.dart';
import '../../utils/chat_unread.dart';
import '../../utils/chat_channel_sort.dart';
import '../../utils/channel_typing_label.dart';
import '../../utils/presence_utils.dart';
import '../../utils/time_ago.dart';
import '../../widgets/chat/chat_connection_banner.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/v_accessible.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/status_dot.dart';
import '../../widgets/profile/cosmetic_avatar.dart';

enum _ChatMode { worlds, dms }

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _didTriggerDmLoad = false;
  bool _didTriggerReadLoad = false;
  bool _didLoadWorldChannels = false;
  _ChatMode _mode = _ChatMode.worlds;
  String? _selectedWorldId;
  Set<String> _mutedWorldIds = {};
  Set<String> _mutedDmRoomIds = {};
  final Map<String, List<Map<String, dynamic>>> _activeResidentsByWorld = {};
  final Map<String, int> _onlineCountByWorld = {};
  final TextEditingController _dmSearchController = TextEditingController();
  String _dmSearchQuery = '';

  @override
  void dispose() {
    _dmSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;
    final residentId = resident?.id;
    final chatState = ref.watch(chatProvider);
    final worldState = ref.watch(worldProvider);
    final joinedWorlds = resident == null
        ? <World>[]
        : (resident.joinedWorldIds
              .map((id) => worldState.worlds[id])
              .whereType<World>()
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)));

    if (residentId != null && !_didTriggerDmLoad) {
      _didTriggerDmLoad = true;
      Future.microtask(() {
        final id = ref.read(residentProvider).resident?.id;
        if (id != null) ref.read(chatProvider.notifier).loadDmRooms(id);
      });
    }

    if (residentId != null && !_didTriggerReadLoad) {
      _didTriggerReadLoad = true;
      Future.microtask(() {
        final id = ref.read(residentProvider).resident?.id;
        if (id != null) ref.read(chatProvider.notifier).loadChannelReads(id);
      });
    }

    if (residentId != null && joinedWorlds.isNotEmpty && !_didLoadWorldChannels) {
      _didLoadWorldChannels = true;
      Future.microtask(() async {
        for (final world in joinedWorlds) {
          await ref.read(channelProvider.notifier).loadChannels(world.id);
        }
        final channelIds = joinedWorlds
            .expand<WorldChannel>(
              (world) =>
                  ref.read(channelProvider).channelsByWorld[world.id] ??
                  const <WorldChannel>[],
            )
            .where((ch) => ch.channelType != ChannelType.voice)
            .map((ch) => ch.id)
            .toList(growable: false);
        if (channelIds.isNotEmpty) {
          await ref
              .read(chatProvider.notifier)
              .loadChannelActivity(channelIds);
        }
        final muted = await WorldMutePrefs.load();
        if (mounted) setState(() => _mutedWorldIds = muted);
        final mutedDm = await DmRoomMutePrefs.load();
        if (mounted) setState(() => _mutedDmRoomIds = mutedDm);
      });
    }

    _ensureSelectedWorld(joinedWorlds);

    return VTabPage(
      title: 'Chat',
      headerActions: [
        VAccessibleHeaderAction(
          label: 'Explore worlds',
          icon: const Icon(VIcons.globe),
          onPress: () => context.go('/worlds'),
        ),
        VAccessibleHeaderAction(
          label: 'New direct message',
          icon: const Icon(VIcons.userPlus),
          onPress: () => openGlobalSearch(context),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: () async {
          final id = ref.read(residentProvider.select((s) => s.resident?.id));
          if (id != null) {
            await Future.wait([
              ref.read(chatProvider.notifier).loadDmRooms(id),
              ref.read(chatProvider.notifier).loadChannelReads(id),
              ref.read(worldProvider.notifier).loadWorlds(),
            ]);
            final selected = _selectedWorldId;
            if (selected != null) {
              await ref.read(channelProvider.notifier).loadChannels(selected);
              final channels =
                  ref.read(channelProvider).channelsByWorld[selected] ?? [];
              await ref
                  .read(chatProvider.notifier)
                  .loadChannelActivity(
                    channels.map((channel) => channel.id).toList(),
                    force: true,
                  );
            }
          }
        },
        child: _buildBody(
          context,
          theme,
          isDark,
          residentId,
          joinedWorlds,
          chatState,
        ),
      ),
    );
  }

  void _loadWorldChannelActivity(String worldId) {
    unawaited(_loadWorldActivity(worldId));
    unawaited(
      ref.read(channelProvider.notifier).loadChannels(worldId).then((_) {
        if (!mounted) return;
        final channels =
            ref.read(channelProvider).channelsByWorld[worldId] ?? [];
        if (channels.isEmpty) return;
        unawaited(
          ref.read(chatProvider.notifier).loadChannelActivity(
            channels.map((channel) => channel.id).toList(),
          ),
        );
      }),
    );
  }

  Future<void> _loadWorldActivity(String worldId) async {
    final results = await Future.wait([
      WorldService.getActiveResidents(worldId),
      WorldService.residentPresenceCounts(worldId),
    ]);
    if (!mounted) return;
    setState(() {
      _activeResidentsByWorld[worldId] =
          results[0] as List<Map<String, dynamic>>;
      _onlineCountByWorld[worldId] =
          (results[1] as ({int total, int online})).online;
    });
  }

  void _ensureSelectedWorld(List<World> joinedWorlds) {
    if (joinedWorlds.isEmpty) {
      if (_selectedWorldId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedWorldId = null);
        });
      }
      return;
    }

    final stillValid = joinedWorlds.any(
      (world) => world.id == _selectedWorldId,
    );
    if (_selectedWorldId == null || !stillValid) {
      final firstId = joinedWorlds.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedWorldId = firstId);
        _loadWorldChannelActivity(firstId);
      });
    } else if (_selectedWorldId != null) {
      final worldId = _selectedWorldId!;
      final channels = ref.read(channelProvider).channelsByWorld[worldId];
      if (channels != null && channels.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(
            ref.read(chatProvider.notifier).loadChannelActivity(
              channels.map((channel) => channel.id).toList(),
            ),
          );
        });
      }
    }
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String? residentId,
    List<World> joinedWorlds,
    ChatState chatState,
  ) {
    // Always use Column + Expanded so the scrollable under RefreshIndicator
    // gets a bounded height (IndexedStack still lays out offstage Chat).
    if (residentId == null) {
      return Column(
        children: [
          const ChatConnectionBanner(),
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                AppEmptyState(
                  title: 'Sign in to view chats',
                  description:
                      'Your worlds and direct messages appear here once you are signed in.',
                  icon: Icons.forum_outlined,
                  illustration: EmptyStateIllustration.chat,
                  actionLabel: 'Sign in',
                  onAction: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const ChatConnectionBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.md,
            VSpacing.sm,
            VSpacing.md,
            VSpacing.sm,
          ),
          child: _ModeSwitch(
            mode: _mode,
            dmUnread: chatState.totalDmUnread(),
            worldCount: joinedWorlds.length,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
        ),
        Expanded(
          child: _mode == _ChatMode.worlds
              ? _buildWorldChats(joinedWorlds)
              : chatState.roomsLoadError != null
              ? _buildDmLoadError(theme, isDark, chatState.roomsLoadError!)
              : chatState.isLoadingRooms
              ? const ScreenLoading.list()
              : chatState.dmRooms.isEmpty
              ? _buildEmptyDmState()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        VSpacing.md,
                        0,
                        VSpacing.md,
                        VSpacing.sm,
                      ),
                      child: VSearchBar(
                        controller: _dmSearchController,
                        hintText: 'Search direct messages...',
                        onChanged: (value) =>
                            setState(() => _dmSearchQuery = value),
                        onClear: () {
                          _dmSearchController.clear();
                          setState(() => _dmSearchQuery = '');
                        },
                      ),
                    ),
                    Expanded(
                      child: _buildRoomList(
                        theme,
                        isDark,
                        chatState.dmRooms,
                        residentId,
                        searchQuery: _dmSearchQuery,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWorldChats(List<World> joinedWorlds) {
    if (joinedWorlds.isEmpty) {
      return AppEmptyState(
        title: 'Join a world to chat',
        description:
            'World channels appear here after you join. Start with Worlds, '
            'then come back to talk.',
        icon: Icons.public_outlined,
        illustration: EmptyStateIllustration.chat,
        actionLabel: 'Browse worlds',
        onAction: () => context.go('/worlds'),
        secondaryActionLabel: 'Submit proof',
        onSecondaryAction: () => context.push('/achievements/submit'),
      );
    }

    final selectedWorld = joinedWorlds.firstWhere(
      (world) => world.id == _selectedWorldId,
      orElse: () => joinedWorlds.first,
    );
    final currentUserId = ref.read(residentProvider).resident?.id;
    final resident = ref.watch(residentProvider).resident;
    final features = ref
        .read(worldProvider.notifier)
        .featuresForWorld(selectedWorld.id);
    final channelState = ref.watch(channelProvider);
    final allChannels = channelState.channelsByWorld[selectedWorld.id] ?? [];
    final channelError = channelState.error;
    final channelLoading = channelState.isLoading;
    final typingByRoom = ref.watch(
      chatProvider.select((s) => s.typingUsers),
    );

    final announcementChannels = allChannels
        .where((c) => c.channelType == ChannelType.announcement)
        .toList();
    final chatChannels = sortChatChannelsWithUnreadFirst(
      channels: allChannels
          .where((c) => c.channelType != ChannelType.announcement)
          .toList(),
      unreadByChannelId: _unreadByChannelId(
        channels: allChannels
            .where((c) => c.channelType != ChannelType.announcement)
            .toList(),
        currentUserId: currentUserId,
      ),
    );

    final world = ref.watch(worldProvider).worlds[selectedWorld.id];
    final residentCount = world?.memberCount ?? 0;

    final unreadByWorld = <String, int>{};
    for (final world in joinedWorlds) {
      final channelIds = (channelState.channelsByWorld[world.id] ?? [])
          .where((ch) => ch.channelType != ChannelType.voice)
          .map((ch) => ch.id);
      final raw = ref
          .read(chatProvider.notifier)
          .unreadForWorldChannels(channelIds, currentUserId: currentUserId);
      unreadByWorld[world.id] = worldRailUnreadCount(
        rawCount: raw,
        muted: _mutedWorldIds.contains(world.id),
      );
    }

    // Discord-like two-panel layout
    return Row(
      children: [
        VWorldRail(
          worlds: joinedWorlds,
          selectedWorldId: selectedWorld.id,
          unreadByWorldId: unreadByWorld,
          mutedWorldIds: _mutedWorldIds,
          onWorldSelected: (world) {
            setState(() => _selectedWorldId = world.id);
            _loadWorldChannelActivity(world.id);
          },
          onAddWorld: () => context.go('/worlds'),
          onToggleMute: (world) async {
            final muted = await WorldMutePrefs.toggle(world.id);
            if (mounted) setState(() => _mutedWorldIds = muted);
          },
        ),
        // Right panel — world header + channel list
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WorldPanelHeader(
                worldName: selectedWorld.name,
                residentCount: residentCount,
                icon: selectedWorld.icon,
                prestige: selectedWorld.prestige,
                onlineCount: _onlineCountByWorld[selectedWorld.id] ?? 0,
                activeResidents:
                    _activeResidentsByWorld[selectedWorld.id] ?? const [],
              ),
              const Divider(height: 1),
              Expanded(
                child: channelLoading
                    ? const ScreenLoading.list()
                    : channelError != null
                    ? AppErrorState(
                        message: 'Failed to load channels',
                        onRetry: () => ref
                            .read(channelProvider.notifier)
                            .loadChannels(selectedWorld.id, force: true),
                      )
                    : allChannels.isEmpty
                    ? _EmptyChannels(worldId: selectedWorld.id)
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                          vertical: VSpacing.sm,
                        ),
                        children: [
                          if (announcementChannels.isNotEmpty) ...[
                            const _ChannelGroupHeader(label: 'Foundation'),
                            ...announcementChannels.map((channel) {
                              final decision = WorldChannelAccessService.decision(
                                world: selectedWorld,
                                channel: channel,
                                features: features,
                                resident: resident,
                              );
                              final unreadCount = decision.canOpen
                                  ? ref.read(chatProvider.notifier).unreadCount(
                                      channel.id,
                                      currentUserId: currentUserId,
                                    )
                                  : 0;
                              final typingLabel = channelTypingLabel(
                                typingByRoom[channel.id] ?? const <String>{},
                                currentUserId: currentUserId,
                              );
                              return _ChannelTile(
                                channel: channel,
                                world: selectedWorld,
                                unreadCount: unreadCount,
                                typingLabel: typingLabel,
                                lockedReason: decision.reason,
                              );
                            }),
                          ],
                          if (chatChannels.isNotEmpty) ...[
                            const _ChannelGroupHeader(label: 'Chat'),
                            ...chatChannels.map((channel) {
                              final decision = WorldChannelAccessService.decision(
                                world: selectedWorld,
                                channel: channel,
                                features: features,
                                resident: resident,
                              );
                              final unreadCount = decision.canOpen &&
                                      channel.channelType != ChannelType.voice
                                  ? ref.read(chatProvider.notifier).unreadCount(
                                      channel.id,
                                      currentUserId: currentUserId,
                                    )
                                  : 0;
                              final typingLabel = channelTypingLabel(
                                typingByRoom[channel.id] ?? const <String>{},
                                currentUserId: currentUserId,
                              );
                              return _ChannelTile(
                                channel: channel,
                                world: selectedWorld,
                                unreadCount: unreadCount,
                                typingLabel: typingLabel,
                                lockedReason: decision.reason,
                              );
                            }),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDmLoadError(ThemeData theme, bool isDark, String message) {
    return AppErrorState(
      message: message,
      onRetry: () {
        final id = ref.read(residentProvider).resident?.id;
        if (id != null) {
          ref.read(chatProvider.notifier).loadDmRooms(id);
        }
      },
    );
  }

  Widget _buildEmptyDmState() {
    return AppEmptyState(
      title: 'No direct messages yet',
      description:
          'Find a resident to message, or jump into a world channel first.',
      icon: Icons.mail_outline,
      illustration: EmptyStateIllustration.chat,
      actionLabel: 'Find residents',
      onAction: () => openGlobalSearch(context),
      secondaryActionLabel: 'Browse worlds',
      onSecondaryAction: () => context.go('/worlds'),
    );
  }

  Widget _buildRoomList(
    ThemeData theme,
    bool isDark,
    List<Map<String, dynamic>> rooms,
    String currentUserId, {
    String searchQuery = '',
  }) {
    final typingByRoom = ref.watch(
      chatProvider.select((s) => s.typingUsers),
    );
    
    final filteredRooms = searchQuery.isEmpty
        ? rooms
        : rooms.where((room) {
            final name = _otherName(room, currentUserId).toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        final room = filteredRooms[index];
        final roomId = room['id'] as String?;
        if (roomId == null || roomId.isEmpty) {
          return const SizedBox.shrink();
        }
        final typingLabel = channelTypingLabel(
          typingByRoom[roomId] ?? const <String>{},
          currentUserId: currentUserId,
        );
        final unreadCount = room['unread_count'] as int? ?? 0;
        final isMuted = _mutedDmRoomIds.contains(roomId);
        
        return Dismissible(
          key: ValueKey(roomId),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              HapticFeedback.lightImpact();
              if (unreadCount > 0) {
                ref.read(chatProvider.notifier).markDmRead(
                      roomId: roomId,
                      residentId: currentUserId,
                    );
              } else {
                ref.read(chatProvider.notifier).markDmUnread(
                      roomId: roomId,
                      residentId: currentUserId,
                    );
              }
              return false;
            } else {
              HapticFeedback.lightImpact();
              final muted = await DmRoomMutePrefs.toggle(roomId);
              if (mounted) {
                setState(() => _mutedDmRoomIds = muted);
              }
              return false;
            }
          },
          background: _SwipeBackground(
            color: unreadCount > 0 ? VColors.success : theme.colorScheme.outline,
            icon: unreadCount > 0 ? Icons.mark_email_read : Icons.mark_email_unread,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: VSpacing.lg),
          ),
          secondaryBackground: _SwipeBackground(
            color: isMuted ? VColors.success : theme.colorScheme.outline.withValues(alpha: 0.45),
            icon: isMuted ? Icons.notifications : Icons.notifications_off,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: VSpacing.lg),
          ),
          child: _DmRoomTile(
            room: room,
            currentUserId: currentUserId,
            otherName: _otherName(room, currentUserId),
            otherAvatar: _otherAvatar(room),
            presence: _presence(room),
            timeLabel: _timeLabel(room['last_message_at'] as String?),
            typingLabel: typingLabel,
            isMuted: isMuted,
          ),
        );
      },
    );
  }

  String _otherName(Map<String, dynamic> room, String currentId) {
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

  String? _otherAvatar(Map<String, dynamic> room) {
    final avatar = room['other_avatar'];
    if (avatar is String && avatar.isNotEmpty) return avatar;
    return null;
  }

  Presence _presence(Map<String, dynamic> room) {
    return presenceFromProfileField(room['other_last_seen_at']);
  }

  Map<String, int> _unreadByChannelId({
    required List<WorldChannel> channels,
    required String? currentUserId,
  }) {
    final notifier = ref.read(chatProvider.notifier);
    final result = <String, int>{};
    for (final channel in channels) {
      if (currentUserId == null) continue;
      result[channel.id] = notifier.unreadCount(
        channel.id,
        currentUserId: currentUserId,
      );
    }
    return result;
  }

  String _timeLabel(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    return timeAgo(dt);
  }
}

class _ModeSwitch extends StatelessWidget {
  final _ChatMode mode;
  final int dmUnread;
  final int worldCount;
  final ValueChanged<_ChatMode> onChanged;

  const _ModeSwitch({
    required this.mode,
    required this.dmUnread,
    required this.worldCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(VSpacing.xs),
      decoration: BoxDecoration(
        color: isDark
            ? VColors.surfaceContainerDark
            : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Worlds',
              count: worldCount,
              icon: Icons.public,
              selected: mode == _ChatMode.worlds,
              onTap: () => onChanged(_ChatMode.worlds),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Direct',
              count: dmUnread,
              icon: Icons.mail_outline,
              selected: mode == _ChatMode.dms,
              showUnreadBadge: dmUnread > 0,
              onTap: () => onChanged(_ChatMode.dms),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final bool showUnreadBadge;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    this.showUnreadBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: VAnimation.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.md,
          vertical: VSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? VColors.brandSoft(Theme.of(context).brightness)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(VRadius.pill),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: VIconSize.sm,
              color: selected
                  ? VColors.brand
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: VSpacing.xs),
            Text(
              showUnreadBadge ? '$label ($count unread)' : '$label $count',
              style: TextStyle(
                color: selected
                    ? VColors.brand
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: selected || showUnreadBadge
                    ? VFontWeight.semiBold
                    : VFontWeight.regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final World world;
  final WorldChannel channel;
  final int unreadCount;
  final String? typingLabel;
  final String? lockedReason;

  const _ChannelTile({
    required this.channel,
    required this.world,
    required this.unreadCount,
    this.typingLabel,
    this.lockedReason,
  });

  IconData get _icon {
    final name = channel.name.toLowerCase();
    if (name == 'info' || name.contains('about')) {
      return Icons.info_outline;
    }
    if (name == 'rules' || name.contains('rule')) {
      return Icons.gavel_outlined;
    }
    if (name == 'roles' || name.contains('role')) {
      return Icons.badge_outlined;
    }
    if (name == 'general' || name == 'chat') {
      return Icons.tag;
    }
    return switch (channel.channelType) {
      ChannelType.announcement => Icons.campaign_outlined,
      ChannelType.feed => Icons.dynamic_feed_outlined,
      ChannelType.text => Icons.tag,
      ChannelType.voice => Icons.local_fire_department,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTyping = typingLabel != null;
    final isLocked = lockedReason != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLocked
            ? null
            : () => context.push(
                  worldChannelDestinationPath(
                    world.id,
                    channel,
                    worldName: world.name,
                  ),
                ),
        child: Opacity(
          opacity: isLocked ? 0.72 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.md,
              vertical: VSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  isLocked ? Icons.lock_outline : _icon,
                  size: VIconSize.md,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: unreadCount > 0
                              ? VFontWeight.semiBold
                              : VFontWeight.regular,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isLocked)
                        Text(
                          lockedReason!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: VColors.tertiary,
                          ),
                        )
                      else if (hasTyping)
                        Text(
                          typingLabel!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: VColors.success,
                            fontStyle: FontStyle.italic,
                            fontWeight: VFontWeight.semiBold,
                          ),
                        )
                      else if (channel.description != null &&
                          channel.description!.isNotEmpty)
                        Text(
                          channel.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isLocked && unreadCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: VSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: VColors.error,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: VColors.onBrand,
                          fontSize: VFontSize.labelSm,
                          fontWeight: VFontWeight.bold,
                        ),
                      ),
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

class _WorldPanelHeader extends StatelessWidget {
  final String worldName;
  final int residentCount;
  final String icon;
  final int prestige;
  final int onlineCount;
  final List<Map<String, dynamic>> activeResidents;

  const _WorldPanelHeader({
    required this.worldName,
    required this.residentCount,
    required this.icon,
    required this.prestige,
    this.onlineCount = 0,
    this.activeResidents = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        VSpacing.sm,
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worldName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: VFontWeight.semiBold,
                  ),
                ),
                Text(
                  '${residentCount == 1 ? '1 Resident' : '$residentCount Residents'}'
                  '${onlineCount > 0 ? ' · $onlineCount online' : ''}'
                  ' · Lv.$prestige',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (activeResidents.isNotEmpty) ...[
                  const SizedBox(height: VSpacing.xs),
                  _ActiveResidentsRow(residents: activeResidents),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveResidentsRow extends StatelessWidget {
  final List<Map<String, dynamic>> residents;

  const _ActiveResidentsRow({required this.residents});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = residents.take(5).toList();

    return Row(
      children: [
        ...preview.map((resident) {
          final id = resident['resident_id'] as String? ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: VSpacing.xs),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CosmeticAvatar(
                  imageUrl: resident['avatar_url'] as String?,
                  seed: id,
                  size: 24,
                ),
                const Positioned(
                  right: -1,
                  bottom: -1,
                  child: StatusDot(presence: Presence.online, size: 8),
                ),
              ],
            ),
          );
        }),
        if (residents.length > preview.length)
          Text(
            '+${residents.length - preview.length}',
            style: theme.textTheme.labelSmall,
          ),
      ],
    );
  }
}

class _ChannelGroupHeader extends StatelessWidget {
  final String label;

  const _ChannelGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.md,
        VSpacing.md,
        VSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: VFontSize.labelSm,
          letterSpacing: 0.5,
          fontWeight: VFontWeight.semiBold,
          color: VColors.tertiary,
        ),
      ),
    );
  }
}

class _EmptyChannels extends ConsumerStatefulWidget {
  final String worldId;

  const _EmptyChannels({required this.worldId});

  @override
  ConsumerState<_EmptyChannels> createState() => _EmptyChannelsState();
}

class _EmptyChannelsState extends ConsumerState<_EmptyChannels> {
  var _bootstrapped = false;
  var _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;
    setState(() => _bootstrapping = true);
    try {
      await ref
          .read(channelProvider.notifier)
          .ensureDefaultChannels(widget.worldId);
    } finally {
      if (mounted) setState(() => _bootstrapping = false);
    }
  }

  Future<void> _retry() async {
    setState(() => _bootstrapping = true);
    try {
      await ref
          .read(channelProvider.notifier)
          .loadChannels(widget.worldId, force: true);
      await ref
          .read(channelProvider.notifier)
          .ensureDefaultChannels(widget.worldId);
    } finally {
      if (mounted) setState(() => _bootstrapping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bootstrapping || ref.watch(channelProvider).isLoading) {
      return const ScreenLoading.list();
    }
    return AppEmptyState(
      title: 'No channels yet',
      description:
          'This world does not have a public channel. Retry setup or open the world page.',
      icon: Icons.tag,
      illustration: EmptyStateIllustration.chat,
      actionLabel: 'Retry setup',
      onAction: _retry,
      secondaryActionLabel: 'Open world',
      onSecondaryAction: () =>
          context.push(exploreWorldPath(widget.worldId)),
    );
  }
}

class _DmRoomTile extends StatefulWidget {
  final Map<String, dynamic> room;
  final String currentUserId;
  final String otherName;
  final String? otherAvatar;
  final Presence presence;
  final String timeLabel;
  final String? typingLabel;
  final bool isMuted;

  const _DmRoomTile({
    required this.room,
    required this.currentUserId,
    required this.otherName,
    required this.otherAvatar,
    required this.presence,
    required this.timeLabel,
    this.typingLabel,
    this.isMuted = false,
  });

  @override
  State<_DmRoomTile> createState() => _DmRoomTileState();
}

class _DmRoomTileState extends State<_DmRoomTile>
    with SingleTickerProviderStateMixin {
  int _previousUnread = 0;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _previousUnread = widget.room['unread_count'] as int? ?? 0;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(_pulseController);
  }

  @override
  void didUpdateWidget(covariant _DmRoomTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = widget.room['unread_count'] as int? ?? 0;
    if (_previousUnread == 0 && current > 0) {
      _pulseController.forward(from: 0);
    }
    _previousUnread = current;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTyping = widget.typingLabel != null;
    final lastMessage = hasTyping
        ? widget.typingLabel!
        : (widget.room['last_message'] as String? ?? '');
    final unreadCount = widget.room['unread_count'] as int? ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            context.push('/chat/${widget.room['id']}', extra: widget.presence),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CosmeticAvatar(imageUrl: widget.otherAvatar),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: StatusDot(presence: widget.presence, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: VSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.otherName.isNotEmpty
                                ? widget.otherName
                                : 'Unknown',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: unreadCount > 0
                                  ? VFontWeight.semiBold
                                  : VFontWeight.regular,
                              color: unreadCount > 0
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.timeLabel.isNotEmpty)
                          Text(
                            widget.timeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessage.isNotEmpty
                                ? lastMessage
                                : 'No messages yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: hasTyping
                                  ? VColors.success
                                  : (unreadCount > 0
                                        ? Theme.of(context).colorScheme.onSurface
                                        : Theme.of(context).colorScheme.onSurfaceVariant),
                              fontWeight: hasTyping
                                  ? VFontWeight.semiBold
                                  : (unreadCount > 0
                                        ? VFontWeight.semiBold
                                        : VFontWeight.regular),
                              fontStyle: hasTyping
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          ScaleTransition(
                            scale: _pulseScale,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  final Color color;
  final IconData icon;
  final AlignmentGeometry alignment;
  final EdgeInsetsGeometry padding;

  const _SwipeBackground({
    required this.color,
    required this.icon,
    required this.alignment,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(VRadius.xl),
      ),
      alignment: alignment,
      padding: padding,
      child: Icon(
        icon,
        size: VIconSize.lg,
        color: Colors.white,
      ),
    );
  }
}
