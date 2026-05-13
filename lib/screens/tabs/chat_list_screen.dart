import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/channel.dart';
import '../../models/world.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../utils/time_ago.dart';
import '../../utils/world_assets.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/core/glass_panel.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/status_dot.dart';
import '../../widgets/profile/cosmetic_avatar.dart';
import '../../widgets/worlds/world_banner.dart';

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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              toolbarHeight: 56,
              elevation: 0,
              backgroundColor: AppColors.surface.withAlpha(204),
              title: const Text('Chats'),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_square,
                    color: AppColors.inkSecondary,
                  ),
                  tooltip: 'New DM',
                  onPressed: () => context.push('/search'),
                ),
              ],
            ),
          ),
        ),
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
        child: _buildBody(context, theme, residentId, joinedWorlds, chatState),
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
    String? residentId,
    List<World> joinedWorlds,
    ChatState chatState,
  ) {
    if (residentId == null) {
      return Center(
        child: Text('Sign in to view chats', style: theme.textTheme.bodyLarge),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.sm,
        Spacing.md,
        120,
      ),
      children: [
        _ModeSwitch(
          mode: _mode,
          dmCount: chatState.dmRooms.length,
          worldCount: joinedWorlds.length,
          onChanged: (mode) => setState(() => _mode = mode),
        ),
        const SizedBox(height: Spacing.md),
        if (_mode == _ChatMode.worlds)
          _buildWorldChats(joinedWorlds)
        else if (chatState.isLoadingRooms)
          const ScreenLoading.list()
        else if (chatState.dmRooms.isEmpty)
          _buildEmptyDmState()
        else
          _buildRoomList(theme, chatState.dmRooms, residentId),
      ],
    );
  }

  Widget _buildWorldChats(List<World> joinedWorlds) {
    if (joinedWorlds.isEmpty) {
      return AppEmptyState(
        title: 'No world chats yet',
        description: 'Join a world to see its public channels here.',
        icon: Icons.public,
        imageAsset: 'assets/generated/empty-chat.jpg',
        actionLabel: 'Explore Worlds',
        onAction: () => context.go('/explore'),
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
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: joinedWorlds.length,
            separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
            itemBuilder: (context, index) {
              final world = joinedWorlds[index];
              return FadeIn(
                delayMs: index * 35,
                child: _JoinedWorldCard(
                  world: world,
                  selected: world.id == selectedWorld.id,
                  onTap: () {
                    setState(() => _selectedWorldId = world.id);
                    ref.read(channelProvider.notifier).loadChannels(world.id);
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: Spacing.lg),
        _SelectedWorldHeader(world: selectedWorld),
        const SizedBox(height: Spacing.sm),
        if (channels.isEmpty)
          FutureBuilder<void>(
            future: ref
                .read(channelProvider.notifier)
                .loadChannels(selectedWorld.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const ScreenLoading(
                  type: ScreenLoadingType.list,
                  itemCount: 3,
                );
              }
              final loaded =
                  ref
                      .watch(channelProvider)
                      .channelsByWorld[selectedWorld.id] ??
                  [];
              if (loaded.isEmpty) {
                return const AppEmptyState(
                  title: 'No channels yet',
                  description:
                      'This world does not have a public channel available.',
                  icon: Icons.forum_outlined,
                );
              }
              return _ChannelList(world: selectedWorld, channels: loaded);
            },
          )
        else
          _ChannelList(world: selectedWorld, channels: channels),
      ],
    );
  }

  Widget _buildEmptyDmState() {
    return AppEmptyState(
      title: 'No direct messages yet',
      description: 'Find residents and start a private conversation.',
      icon: Icons.chat_bubble_outline,
      imageAsset: 'assets/generated/empty-chat.jpg',
      actionLabel: 'Find Residents',
      onAction: () => context.go('/search'),
    );
  }

  Widget _buildRoomList(
    ThemeData theme,
    List<Map<String, dynamic>> rooms,
    String currentUserId,
  ) {
    return Column(
      children: [
        for (final entry in rooms.asMap().entries)
          FadeIn(
            delayMs: entry.key * 40,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _DmRoomTile(
                room: entry.value,
                currentUserId: currentUserId,
                otherName: _otherName(entry.value, currentUserId),
                otherAvatar: _otherAvatar(entry.value),
                presence: _presence(entry.value),
                timeLabel: _timeLabel(
                  entry.value['last_message_at'] as String?,
                ),
              ),
            ),
          ),
      ],
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
    final lastAt = room['last_message_at'] as String?;
    if (lastAt == null) return Presence.offline;
    final last = DateTime.tryParse(lastAt);
    if (last == null) return Presence.offline;
    return DateTime.now().difference(last).inMinutes < 5
        ? Presence.online
        : Presence.offline;
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
    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.xs),
      borderRadius: BorderRadius.circular(RadiusTokens.full),
      child: Row(
        children: [
          _ModeButton(
            label: 'Worlds',
            count: worldCount,
            icon: Icons.public,
            selected: mode == _ChatMode.worlds,
            onTap: () => onChanged(_ChatMode.worlds),
          ),
          _ModeButton(
            label: 'DMs',
            count: dmCount,
            icon: Icons.forum,
            selected: mode == _ChatMode.dms,
            onTap: () => onChanged(_ChatMode.dms),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AnimDurations.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.tertiary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(RadiusTokens.full),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: IconSizes.sm,
                color: selected ? AppColors.tertiary : AppColors.inkMuted,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                '$label $count',
                style: TextStyle(
                  color: selected ? AppColors.tertiary : AppColors.inkMuted,
                  fontWeight: selected ? FontWeights.bold : FontWeights.regular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinedWorldCard extends StatelessWidget {
  final World world;
  final bool selected;
  final VoidCallback onTap;

  const _JoinedWorldCard({
    required this.world,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = WorldAssets.colorForPrestige(world.prestige);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimDurations.fast,
        width: selected ? 220 : 178,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
          border: Border.all(
            color: selected ? accent : AppColors.glassBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WorldBanner(
              worldId: world.id,
              assetKey: world.assetKey,
              worldType: world.type,
              prestige: world.prestige,
              height: 116,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.canvas.withValues(alpha: 0.06),
                    AppColors.canvas.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Icon(
                      selected ? Icons.check_circle : Icons.public,
                      color: selected ? accent : AppColors.inkMuted,
                      size: IconSizes.md,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    world.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeights.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${world.memberCount} residents',
                    style: const TextStyle(
                      color: AppColors.inkSecondary,
                      fontSize: FontSizes.labelSm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedWorldHeader extends StatelessWidget {
  final World world;

  const _SelectedWorldHeader({required this.world});

  @override
  Widget build(BuildContext context) {
    final accent = WorldAssets.colorForPrestige(world.prestige);
    return Row(
      children: [
        Container(
          width: 3,
          height: 28,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                world.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeights.bold,
                ),
              ),
              Text(
                'World channels',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'View World',
          icon: const Icon(Icons.open_in_new, size: IconSizes.md),
          color: AppColors.inkSecondary,
          onPressed: () => context.push('/explore/${world.id}'),
        ),
      ],
    );
  }
}

class _ChannelList extends ConsumerWidget {
  final World world;
  final List<WorldChannel> channels;

  const _ChannelList({required this.world, required this.channels});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref
        .read(worldProvider.notifier)
        .featuresForWorld(world.id);
    final visible = channels.where((channel) {
      if (channel.name == 'lounge' && !features.lounge) return false;
      return true;
    }).toList()..sort((a, b) => a.position.compareTo(b.position));

    if (visible.isEmpty) {
      return const AppEmptyState(
        title: 'No channels yet',
        description: 'This world does not have a public channel available.',
        icon: Icons.forum_outlined,
      );
    }
    Future.microtask(
      () => ref
          .read(chatProvider.notifier)
          .loadChannelActivity(visible.map((channel) => channel.id).toList()),
    );

    return Column(
      children: [
        for (final entry in visible.asMap().entries)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: _WorldChannelTile(
              world: world,
              channel: entry.value,
              unreadCount: ref
                  .read(chatProvider.notifier)
                  .unreadCount(entry.value.id),
            ),
          ),
      ],
    );
  }
}

class _WorldChannelTile extends StatelessWidget {
  final World world;
  final WorldChannel channel;
  final int unreadCount;

  const _WorldChannelTile({
    required this.world,
    required this.channel,
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
    final channelName = Uri.encodeComponent(channel.name);
    final channelId = Uri.encodeComponent(channel.id);

    return GlassPanel(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(RadiusTokens.xl),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.xs,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(RadiusTokens.lg),
          ),
          child: Icon(_icon, color: AppColors.primary, size: IconSizes.md),
        ),
        title: Text(
          '# ${channel.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeights.bold,
          ),
        ),
        subtitle: Text(
          channel.description ?? 'Open discussion in ${world.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.inkMuted),
        ),
        trailing: unreadCount > 0
            ? _UnreadBadge(count: unreadCount)
            : const Icon(
                Icons.chevron_right,
                color: AppColors.inkMuted,
                size: IconSizes.md,
              ),
        onTap: () =>
            context.push('/explore/${world.id}/$channelName?id=$channelId'),
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
    final lastMessage = room['last_message'] as String? ?? '';
    final unreadCount = room['unread_count'] as int? ?? 0;

    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.md),
      borderRadius: BorderRadius.circular(RadiusTokens.xl),
      child: InkWell(
        onTap: () => context.push('/chat/${room['id']}'),
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
        child: Row(
          children: [
            CosmeticAvatar(imageUrl: otherAvatar, size: 48),
            const SizedBox(width: Spacing.md),
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
                            fontWeight: FontWeights.bold,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.inkMuted,
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
                                ? AppColors.ink
                                : AppColors.inkMuted,
                            fontWeight: unreadCount > 0
                                ? FontWeights.semiBold
                                : FontWeights.regular,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) _UnreadBadge(count: unreadCount),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: Spacing.sm),
            StatusDot(presence: presence, size: 8),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: AppColors.onTertiary,
          fontSize: 11,
          fontWeight: FontWeights.bold,
        ),
      ),
    );
  }
}
