import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../../models/channel.dart';
import '../../models/world.dart';
import '../../router/search_navigation.dart';
import '../../router/world_navigation.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/presence_utils.dart';
import '../../utils/time_ago.dart';
import '../../widgets/chat/chat_connection_banner.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/profile/cosmetic_avatar.dart';

/// Discord-style Home: server rail | channels/DMs | feed placeholder.
class CommuneHomeScreen extends ConsumerStatefulWidget {
  const CommuneHomeScreen({super.key});

  @override
  ConsumerState<CommuneHomeScreen> createState() => _CommuneHomeScreenState();
}

class _CommuneHomeScreenState extends ConsumerState<CommuneHomeScreen> {
  String? _selectedWorldId;
  bool _showDmList = false;
  bool _showChannelPanel = true;
  bool _didTriggerDmLoad = false;

  @override
  Widget build(BuildContext context) {
    final resident = ref.watch(residentProvider).resident;
    final residentId = resident?.id;
    final worldState = ref.watch(worldProvider);
    final joinedWorlds = resident == null
        ? <World>[]
        : (resident.joinedWorldIds
              .map((id) => worldState.worlds[id])
              .whereType<World>()
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name)));

    _ensureSelectedWorld(joinedWorlds);

    if (residentId != null && !_didTriggerDmLoad) {
      _didTriggerDmLoad = true;
      Future.microtask(() {
        final id = ref.read(residentProvider).resident?.id;
        if (id != null) ref.read(chatProvider.notifier).loadDmRooms(id);
      });
    }

    final unreadByWorld = <String, int>{};
    for (final world in joinedWorlds) {
      final channels = ref.watch(channelProvider).channelsByWorld[world.id] ?? [];
      var count = 0;
      for (final ch in channels) {
        count += ref.read(chatProvider.notifier).unreadCount(
          ch.id,
          currentUserId: residentId,
        );
      }
      if (count > 0) unreadByWorld[world.id] = count;
    }

    return ColoredBox(
      color: VCommuneColors.surfacePrimary,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const ChatConnectionBanner(),
            _HomeTopBar(
              onSearch: () => openGlobalSearch(context),
              onFeed: () => context.push('/feed'),
            ),
            Expanded(
              child: VOverlappingPanels(
                showSecondary: _showChannelPanel && !_showDmList,
                onSecondaryDismissed: () =>
                    setState(() => _showChannelPanel = false),
                primary: VServerRail(
                  worlds: joinedWorlds,
                  selectedWorldId: _selectedWorldId,
                  unreadByWorldId: unreadByWorld,
                  onWorldSelected: (world) {
                    setState(() {
                      _selectedWorldId = world.id;
                      _showDmList = false;
                      _showChannelPanel = true;
                    });
                    ref.read(channelProvider.notifier).loadChannels(world.id);
                  },
                  onAddWorld: () => context.push('/explore/discover'),
                ),
                secondary: _showDmList
                    ? _DmListPanel(residentId: residentId)
                    : _ChannelListPanel(
                        worlds: joinedWorlds,
                        selectedWorldId: _selectedWorldId,
                        residentId: residentId,
                      ),
                content: _HomeContentPlaceholder(
                  showDmList: _showDmList,
                  onToggleDms: () => setState(() {
                    _showDmList = true;
                    _showChannelPanel = true;
                  }),
                  onToggleWorlds: () => setState(() {
                    _showDmList = false;
                    _showChannelPanel = true;
                  }),
                  onOpenChannels: joinedWorlds.isNotEmpty
                      ? () => setState(() => _showChannelPanel = true)
                      : null,
                ),
              ),
            ),
          ],
        ),
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
    final valid = joinedWorlds.any((w) => w.id == _selectedWorldId);
    if (_selectedWorldId == null || !valid) {
      final id = joinedWorlds.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedWorldId = id);
        ref.read(channelProvider.notifier).loadChannels(id);
      });
    }
  }
}

class _HomeTopBar extends StatelessWidget {
  final VoidCallback onSearch;
  final VoidCallback onFeed;

  const _HomeTopBar({required this.onSearch, required this.onFeed});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: VCommuneColors.surfaceSecondary,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.sm,
      ),
      child: Row(
        children: [
          const Text(
            'Home',
            style: TextStyle(
              fontSize: VFontSize.headlineMd,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Search',
            onPressed: onSearch,
            icon: const Icon(Icons.search, color: VCommuneColors.textMuted),
          ),
          TextButton.icon(
            onPressed: onFeed,
            icon: const Icon(Icons.dynamic_feed, size: 18),
            label: const Text('Feed'),
            style: TextButton.styleFrom(
              foregroundColor: VCommuneColors.textLink,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelListPanel extends ConsumerWidget {
  final List<World> worlds;
  final String? selectedWorldId;
  final String? residentId;

  const _ChannelListPanel({
    required this.worlds,
    required this.selectedWorldId,
    required this.residentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (worlds.isEmpty) {
      return ColoredBox(
        color: VCommuneColors.surfaceSecondary,
        child: AppEmptyState(
          title: 'No worlds yet',
          description: 'Join a world to see channels.',
          icon: Icons.public_outlined,
          actionLabel: 'Discover',
          onAction: () => context.push('/explore/discover'),
        ),
      );
    }

    final world = worlds.firstWhere(
      (w) => w.id == selectedWorldId,
      orElse: () => worlds.first,
    );
    final channelState = ref.watch(channelProvider);
    final channels = channelState.channelsByWorld[world.id] ?? [];

    return ColoredBox(
      color: VCommuneColors.surfaceSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.md,
              VSpacing.md,
              VSpacing.md,
              VSpacing.sm,
            ),
            child: Text(
              world.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: VFontSize.headlineSm,
                fontWeight: VFontWeight.bold,
                color: VCommuneColors.headerPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: VCommuneColors.dividerSubtle),
          Expanded(
            child: channelState.isLoading
                ? const ScreenLoading.list()
                : channels.isEmpty
                ? AppEmptyState(
                    title: 'No channels',
                    description: 'Channels will appear here.',
                    icon: Icons.tag_outlined,
                    onAction: () => context.push(exploreWorldPath(world.id)),
                    actionLabel: 'Open world',
                  )
                : ListView.builder(
                    itemCount: channels.length,
                    itemBuilder: (context, index) {
                      final channel = channels[index];
                      final unread = ref
                          .read(chatProvider.notifier)
                          .unreadCount(
                            channel.id,
                            currentUserId: residentId,
                          );
                      return VChannelTile(
                        icon: _channelIcon(channel.channelType),
                        name: channel.name,
                        unreadCount: unread,
                        onTap: () => context.push(
                          worldChannelDestinationPath(
                            world.id,
                            channel,
                            worldName: world.name,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _channelIcon(ChannelType type) {
    return switch (type) {
      ChannelType.voice => Icons.volume_up_outlined,
      ChannelType.announcement => Icons.campaign_outlined,
      _ => Icons.tag,
    };
  }
}

class _DmListPanel extends ConsumerWidget {
  final String? residentId;

  const _DmListPanel({required this.residentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider);
    if (residentId == null) {
      return const ColoredBox(
        color: VCommuneColors.surfaceSecondary,
        child: Center(child: Text('Sign in to view messages')),
      );
    }

    return ColoredBox(
      color: VCommuneColors.surfaceSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(VSpacing.md),
            child: Text(
              'Direct Messages',
              style: TextStyle(
                fontSize: VFontSize.headlineSm,
                fontWeight: VFontWeight.bold,
                color: VCommuneColors.headerPrimary,
              ),
            ),
          ),
          Divider(height: 1, color: VCommuneColors.dividerSubtle),
          Expanded(
            child: chatState.isLoadingRooms
                ? const ScreenLoading.list()
                : chatState.dmRooms.isEmpty
                ? AppEmptyState(
                    title: 'No messages yet',
                    description: 'Start a conversation from search.',
                    icon: Icons.chat_bubble_outline,
                    onAction: () => openGlobalSearch(context),
                    actionLabel: 'Find people',
                  )
                : ListView.builder(
                    itemCount: chatState.dmRooms.length,
                    itemBuilder: (context, index) {
                      final room = chatState.dmRooms[index];
                      final name = _dmOtherName(room, residentId!);
                      final avatar = _dmOtherAvatar(room);
                      final presence = presenceFromProfileField(
                        room['other_last_seen_at'],
                      );
                      final time = _dmTimeLabel(
                        room['last_message_at'] as String?,
                      );
                      return ListTile(
                        dense: true,
                        leading: CosmeticAvatar(imageUrl: avatar, size: 40),
                        title: Text(
                          name.isEmpty ? 'Conversation' : name,
                          style: const TextStyle(
                            color: VCommuneColors.headerPrimary,
                            fontWeight: VFontWeight.semiBold,
                          ),
                        ),
                        subtitle: time.isEmpty
                            ? null
                            : Text(
                                time,
                                style: const TextStyle(
                                  color: VCommuneColors.textMuted,
                                  fontSize: VFontSize.labelSm,
                                ),
                              ),
                        onTap: () => context.push(
                          '/chat/${room['id']}',
                          extra: presence,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _dmOtherName(Map<String, dynamic> room, String currentId) {
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

String? _dmOtherAvatar(Map<String, dynamic> room) {
  final avatar = room['other_avatar'];
  if (avatar is String && avatar.isNotEmpty) return avatar;
  return null;
}

String _dmTimeLabel(String? iso) {
  if (iso == null) return '';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  return timeAgo(dt);
}

class _HomeContentPlaceholder extends StatelessWidget {
  final bool showDmList;
  final VoidCallback onToggleDms;
  final VoidCallback onToggleWorlds;
  final VoidCallback? onOpenChannels;

  const _HomeContentPlaceholder({
    required this.showDmList,
    required this.onToggleDms,
    required this.onToggleWorlds,
    this.onOpenChannels,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VCommuneColors.surfacePrimary,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showDmList ? Icons.chat_bubble_outline : Icons.tag,
                size: 56,
                color: VCommuneColors.textMuted,
              ),
              const SizedBox(height: VSpacing.md),
              Text(
                showDmList ? 'Select a conversation' : 'Select a channel',
                style: const TextStyle(
                  fontSize: VFontSize.headlineSm,
                  fontWeight: VFontWeight.semiBold,
                  color: VCommuneColors.headerPrimary,
                ),
              ),
              const SizedBox(height: VSpacing.sm),
              const Text(
                'Pick a world and channel on the left, or open your feed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: VCommuneColors.textMuted),
              ),
              const SizedBox(height: VSpacing.lg),
              Wrap(
                spacing: VSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: onToggleWorlds,
                    child: const Text('Worlds'),
                  ),
                  OutlinedButton(
                    onPressed: onToggleDms,
                    child: const Text('DMs'),
                  ),
                  if (onOpenChannels != null)
                    FilledButton(
                      onPressed: onOpenChannels,
                      child: const Text('Channels'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
