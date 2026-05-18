import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/channel.dart';
import '../../models/world.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/time_ago.dart';
import '../../widgets/core/status_dot.dart';
import '../../widgets/profile/cosmetic_avatar.dart';
import '../../ui/icons/v_icons.dart';

enum _ChatMode { worlds, dms }

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  bool _didTriggerDmLoad = false;
  bool _didTriggerReadLoad = false;
  _ChatMode _mode = _ChatMode.worlds;
  String? _selectedWorldId;

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
        : resident.joinedWorldIds
              .map((id) => worldState.worlds[id])
              .whereType<World>()
              .toList();

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

    _ensureSelectedWorld(joinedWorlds);

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor:
            (isDark ? VColors.surfaceDark : VColors.surface).withValues(
              alpha: 0.86,
            ),
        elevation: 0,
        title: Text(
          'Messages',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.person_add_outlined,
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
            tooltip: 'New DM',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
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
        child: _buildBody(context, theme, isDark, residentId, joinedWorlds, chatState),
      ),
    );
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
        ref.read(channelProvider.notifier).loadChannels(firstId);
      });
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
    if (residentId == null) {
      return Center(
        child: Text(
          'Sign in to view chats',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.md,
            VSpacing.sm,
            VSpacing.md,
            VSpacing.sm,
          ),
          child: _ModeSwitch(
            mode: _mode,
            dmCount: chatState.dmRooms.length,
            worldCount: joinedWorlds.length,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
        ),
        Expanded(
          child: _mode == _ChatMode.worlds
              ? _buildWorldChats(joinedWorlds)
              : chatState.isLoadingRooms
                  ? const Center(child: CircularProgressIndicator())
                  : chatState.dmRooms.isEmpty
                      ? _buildEmptyDmState()
                      : _buildRoomList(theme, isDark, chatState.dmRooms, residentId),
        ),
      ],
    );
  }

  Widget _buildWorldChats(List<World> joinedWorlds) {
    if (joinedWorlds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.public_outlined,
              size: 48,
              color: VColors.onSurfaceVariant,
            ),
            const SizedBox(height: VSpacing.md),
            const Text(
              'No world chats yet',
              style: TextStyle(fontWeight: VFontWeight.semiBold),
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              'Join a world to see its channels here.',
              style: TextStyle(
                color: VColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push('/explore'),
              icon: const Icon(VIcons.globe),
              label: const Text('Explore Worlds'),
            ),
          ],
        ),
      );
    }

    final selectedWorld = joinedWorlds.firstWhere(
      (world) => world.id == _selectedWorldId,
      orElse: () => joinedWorlds.first,
    );
    final channels =
        ref.watch(channelProvider).channelsByWorld[selectedWorld.id] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
            itemCount: joinedWorlds.length,
            separatorBuilder: (_, _) => const SizedBox(width: VSpacing.sm),
            itemBuilder: (context, index) {
              final world = joinedWorlds[index];
              final isSelected = world.id == selectedWorld.id;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedWorldId = world.id);
                  ref.read(channelProvider.notifier).loadChannels(world.id);
                },
                child: AnimatedContainer(
                  duration: VAnimation.fast,
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.md,
                    vertical: VSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? VColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                    border: Border.all(
                      color: isSelected
                          ? VColors.primary.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.public,
                        size: VIconSize.sm,
                        color: isSelected
                            ? VColors.primary
                            : VColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: VSpacing.xs),
                      Text(
                        world.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? VFontWeight.semiBold
                              : VFontWeight.regular,
                          color: isSelected
                              ? VColors.primary
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: channels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag,
                        size: 48,
                        color: VColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: VSpacing.md),
                      const Text(
                        'No channels yet',
                        style: TextStyle(fontWeight: VFontWeight.semiBold),
                      ),
                      const SizedBox(height: VSpacing.xs),
                      Text(
                        'This world does not have a public channel.',
                        style: TextStyle(color: VColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    final channel = channels[index];
                    final unreadCount = ref
                        .read(chatProvider.notifier)
                        .unreadCount(channel.id);
                    return _ChannelTile(
                      channel: channel,
                      world: selectedWorld,
                      unreadCount: unreadCount,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyDmState() {
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
            'No direct messages yet',
            style: TextStyle(fontWeight: VFontWeight.semiBold),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'Find residents and start a conversation.',
            style: TextStyle(color: VColors.onSurfaceVariant),
          ),
          const SizedBox(height: VSpacing.lg),
          FilledButton.icon(
            onPressed: () => context.push('/search'),
            icon: const Icon(VIcons.search),
            label: const Text('Find Residents'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(
    ThemeData theme,
    bool isDark,
    List<Map<String, dynamic>> rooms,
    String currentUserId,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _DmRoomTile(
          room: room,
          currentUserId: currentUserId,
          otherName: _otherName(room, currentUserId),
          otherAvatar: _otherAvatar(room),
          presence: _presence(room),
          timeLabel: _timeLabel(room['last_message_at'] as String?),
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
    final otherLastSeen = room['other_last_seen_at'] as int?;
    if (otherLastSeen == null || otherLastSeen == 0) {
      final lastAt = room['last_message_at'] as String?;
      if (lastAt == null) return Presence.offline;
      final last = DateTime.tryParse(lastAt);
      if (last == null) return Presence.offline;
      final diff = DateTime.now().difference(last).inMinutes;
      if (diff < 2) return Presence.online;
      if (diff < 10) return Presence.idle;
      return Presence.offline;
    }
    final lastSeen = DateTime.fromMillisecondsSinceEpoch(otherLastSeen);
    final diff = DateTime.now().difference(lastSeen).inMinutes;
    if (diff < 2) return Presence.online;
    if (diff < 10) return Presence.idle;
    return Presence.offline;
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
  final int dmCount;
  final int worldCount;
  final ValueChanged<_ChatMode> onChanged;

  const _ModeSwitch({
    required this.mode,
    required this.dmCount,
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
            ? VColors.glassBackgroundDark
            : VColors.glassBackground,
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: Border.all(
          color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
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
              label: 'DMs',
              count: dmCount,
              icon: Icons.forum,
              selected: mode == _ChatMode.dms,
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
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              ? VColors.primary.withValues(alpha: 0.15)
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
                  ? VColors.primary
                  : (isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant),
            ),
            const SizedBox(width: VSpacing.xs),
            Text(
              '$label $count',
              style: TextStyle(
                color: selected
                    ? VColors.primary
                    : (isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant),
                fontWeight: selected
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

  const _ChannelTile({
    required this.channel,
    required this.world,
    required this.unreadCount,
  });

  IconData get _icon => switch (channel.channelType) {
        ChannelType.announcement => Icons.campaign,
        ChannelType.feed => Icons.dynamic_feed,
        ChannelType.text => Icons.tag,
        ChannelType.voice => Icons.volume_up,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final channelName = Uri.encodeComponent(channel.name);
    final channelId = Uri.encodeComponent(channel.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            context.push('/explore/${world.id}/$channelName?id=$channelId'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                _icon,
                size: VIconSize.md,
                color: unreadCount > 0
                    ? (isDark ? VColors.onSurfaceDark : VColors.onSurface)
                    : (isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant),
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
                        color: unreadCount > 0
                            ? (isDark ? VColors.onSurfaceDark : VColors.onSurface)
                            : (isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant),
                      ),
                    ),
                    if (channel.description != null && channel.description!.isNotEmpty)
                      Text(
                        channel.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: VColors.primary,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(
                      color: VColors.onPrimary,
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DmRoomTile extends StatelessWidget {
  final Map<String, dynamic> room;
  final String currentUserId;
  final String otherName;
  final String? otherAvatar;
  final Presence presence;
  final String timeLabel;

  const _DmRoomTile({
    required this.room,
    required this.currentUserId,
    required this.otherName,
    required this.otherAvatar,
    required this.presence,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lastMessage = room['last_message'] as String? ?? '';
    final unreadCount = room['unread_count'] as int? ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/chat/${room['id']}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CosmeticAvatar(
                    imageUrl: otherAvatar,
                    size: 48,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? VColors.surfaceDark : VColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? VColors.surfaceDark : VColors.surface,
                          width: 2,
                        ),
                      ),
                      child: StatusDot(
                        presence: presence,
                        size: 10,
                      ),
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
                            otherName.isNotEmpty ? otherName : 'Unknown',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: unreadCount > 0
                                  ? VFontWeight.semiBold
                                  : VFontWeight.regular,
                              color: unreadCount > 0
                                  ? (isDark ? VColors.onSurfaceDark : VColors.onSurface)
                                  : (isDark ? VColors.onSurfaceDark : VColors.onSurface),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
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
                              color: unreadCount > 0
                                  ? (isDark ? VColors.onSurfaceDark : VColors.onSurface)
                                  : (isDark
                                      ? VColors.onSurfaceVariantDark
                                      : VColors.onSurfaceVariant),
                              fontWeight: unreadCount > 0
                                  ? VFontWeight.semiBold
                                  : VFontWeight.regular,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: VColors.primary,
                              shape: BoxShape.circle,
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
