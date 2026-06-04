import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/channel.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../services/world_channel_access_service.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/empty_state.dart';

class WorldChannelList extends ConsumerStatefulWidget {
  final String worldId;

  const WorldChannelList({super.key, required this.worldId});

  @override
  ConsumerState<WorldChannelList> createState() => _WorldChannelListState();
}

class _WorldChannelListState extends ConsumerState<WorldChannelList> {
  Map<String, bool> _wardExpanded = {};
  String? _lastActivityKey;

  static const String _prefsKey = 'ward_collapsed_state';

  @override
  void initState() {
    super.initState();
    _loadCollapsedState();
  }

  Future<void> _loadCollapsedState() async {
    final prefs = await SharedPreferences.getInstance();
    final collapsedList = prefs.getStringList(_prefsKey) ?? [];
    final collapsed = Set<String>.from(collapsedList);
    setState(() {
      _wardExpanded = {};
      _collapsedState = collapsed;
    });
  }

  Set<String> _collapsedState = {};

  Future<void> _toggleWard(String wardId) async {
    final newState = !_isExpanded(wardId);
    setState(() {
      _wardExpanded[wardId] = newState;
      if (newState) {
        _collapsedState.remove(wardId);
      } else {
        _collapsedState.add(wardId);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _collapsedState.toList());
  }

  bool _isExpanded(String wardId) =>
      _wardExpanded[wardId] ?? !_collapsedState.contains(wardId);

  @override
  Widget build(BuildContext context) {
    final allChannels =
        ref.watch(channelProvider).channelsByWorld[widget.worldId] ?? [];
    final features = ref
        .read(worldProvider.notifier)
        .featuresForWorld(widget.worldId);
    final channels = allChannels;
    final activityIds = channels
        .where((c) => c.channelType != ChannelType.voice)
        .map((c) => c.id)
        .toList();
    final activityKey = activityIds.join('|');
    if (_lastActivityKey != activityKey) {
      _lastActivityKey = activityKey;
      Future.microtask(
        () => ref.read(chatProvider.notifier).loadChannelActivity(activityIds),
      );
    }
    final theme = Theme.of(context);
    final world = ref.watch(worldProvider).worlds[widget.worldId];
    final resident = ref.watch(residentProvider).resident;

    if (channels.isEmpty) {
      return const AppEmptyState(
        title: 'No channels yet',
        description: 'This world does not have a public channel available.',
        icon: Icons.forum_outlined,
      );
    }

    // Group channels by ward
    final ungrouped = channels.where((c) => c.wardId == null).toList();
    final wardMap = <String, List<WorldChannel>>{};
    for (final c in channels) {
      if (c.wardId != null) {
        wardMap.putIfAbsent(c.wardId!, () => []).add(c);
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: VSpacing.sm,
            bottom: VSpacing.xs,
          ),
          child: Text(
            'Channels',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: VFontWeight.bold,
            ),
          ),
        ),
        // Render wards with collapsible headers
        for (final entry in wardMap.entries)
          _buildWardGroup(
            entry.key,
            entry.value.first.wardName ?? entry.key,
            entry.value,
          ),
        // Ungrouped channels
        for (final ch in ungrouped)
          _buildChannelTile(ch, world, features, resident),
      ],
    );
  }

  Widget _buildChannelTile(
    WorldChannel channel,
    World? world,
    WorldFeatures features,
    Resident? resident,
  ) {
    final decision = world == null
        ? const ChannelAccessDecision.locked('World unavailable.')
        : WorldChannelAccessService.decision(
            world: world,
            channel: channel,
            features: features,
            resident: resident,
          );
    return _ChannelTile(
      channel: channel,
      unreadCount: decision.canOpen && channel.channelType != ChannelType.voice
          ? ref.read(chatProvider.notifier).unreadCount(
                channel.id,
                currentUserId: resident?.id,
              )
          : 0,
      lockedReason: decision.reason,
      onTap: decision.canOpen && world != null
          ? () => context.push(
                worldChannelDestinationPath(
                  widget.worldId,
                  channel,
                  worldName: world.name,
                ),
              )
          : null,
    );
  }

  Widget _buildWardGroup(
    String wardId,
    String wardName,
    List<WorldChannel> wardChannels,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final expanded = _isExpanded(wardId);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _toggleWard(wardId),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.lg,
              VSpacing.sm,
              VSpacing.lg,
              VSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.arrow_drop_down : Icons.chevron_right,
                  size: VIconSize.sm,
                  color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
                ),
                const SizedBox(width: VSpacing.xs),
                Text(
                  wardName.toUpperCase(),
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.semiBold,
                    color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final ch in wardChannels)
            _buildChannelTile(
              ch,
              ref.watch(worldProvider).worlds[widget.worldId],
              ref.read(worldProvider.notifier).featuresForWorld(widget.worldId),
              ref.watch(residentProvider).resident,
            ),
      ],
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final WorldChannel channel;
  final int unreadCount;
  final VoidCallback? onTap;
  final String? lockedReason;

  const _ChannelTile({
    required this.channel,
    required this.unreadCount,
    required this.onTap,
    this.lockedReason,
  });

  IconData get _icon => switch (channel.channelType) {
    ChannelType.announcement => Icons.campaign,
    ChannelType.feed => Icons.dynamic_feed,
    ChannelType.text => Icons.tag,
    ChannelType.voice => Icons.local_fire_department,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.sm,
            vertical: VSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                lockedReason != null ? Icons.lock_outline : _icon,
                size: 20,
                color: lockedReason != null
                    ? theme.colorScheme.onSurfaceVariant
                    : unreadCount > 0
                        ? (isDark ? VColors.onSurfaceDark : VColors.onSurface)
                        : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            channel.channelType == ChannelType.voice
                                ? channel.name
                                : '# ${channel.name}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: unreadCount > 0
                                  ? VFontWeight.bold
                                  : VFontWeight.regular,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: VColors.error,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                fontSize: VFontSize.labelSm,
                                fontWeight: VFontWeight.bold,
                                color: VColors.onPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (lockedReason != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        lockedReason!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: VColors.tertiary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (channel.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        channel.description!,
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
