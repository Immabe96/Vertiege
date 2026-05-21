import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/channel.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../core/empty_state.dart';

class WorldChannelList extends ConsumerStatefulWidget {
  final String worldId;

  const WorldChannelList({super.key, required this.worldId});

  @override
  ConsumerState<WorldChannelList> createState() => _WorldChannelListState();
}

class _WorldChannelListState extends ConsumerState<WorldChannelList> {
  Map<String, bool> _wardExpanded = {};

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

  bool _isExpanded(String wardId) => _wardExpanded[wardId] ?? !_collapsedState.contains(wardId);

  @override
  Widget build(BuildContext context) {
    final allChannels =
        ref.watch(channelProvider).channelsByWorld[widget.worldId] ?? [];
    final features = ref
        .read(worldProvider.notifier)
        .featuresForWorld(widget.worldId);
    final channels = allChannels.where((c) {
      if (c.name == 'lounge' && !features.lounge) return false;
      return true;
    }).toList();
    Future.microtask(
      () => ref
          .read(chatProvider.notifier)
          .loadChannelActivity(channels.map((c) => c.id).toList()),
    );
    final theme = Theme.of(context);

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 4,
          ),
          child: Text(
            'Channels',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeights.bold,
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
          _ChannelTile(
            channel: ch,
            unreadCount: ref.read(chatProvider.notifier).unreadCount(ch.id),
            onTap: () => context.push(
              '/explore/${widget.worldId}/${ch.name}?id=${ch.id}',
            ),
          ),
      ],
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
      children: [
        GestureDetector(
          onTap: () => _toggleWard(wardId),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg,
              Spacing.sm,
              Spacing.lg,
              Spacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.arrow_drop_down : Icons.chevron_right,
                  size: IconSizes.sm,
                  color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
                ),
                const SizedBox(width: Spacing.xs),
                Text(
                  wardName.toUpperCase(),
                  style: TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.semiBold,
                    color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                    letterSpacing: LetterSpacing.label,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          for (final ch in wardChannels)
            _ChannelTile(
              channel: ch,
              unreadCount: ref.read(chatProvider.notifier).unreadCount(ch.id),
              onTap: () => context.push(
                '/explore/${widget.worldId}/${ch.name}?id=${ch.id}',
              ),
            ),
      ],
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final WorldChannel channel;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.unreadCount,
    required this.onTap,
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

    return ListTile(
      dense: true,
      leading: Icon(
        _icon,
        size: 20,
        color: unreadCount > 0
            ? isDark ? VColors.onSurfaceDark : VColors.onSurface
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '# ${channel.name}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: unreadCount > 0
                    ? FontWeights.bold
                    : FontWeights.regular,
              ),
            ),
          ),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
      subtitle: channel.description != null
          ? Text(
              channel.description!,
              style: theme.textTheme.labelSmall,
              maxLines: 1,
            )
          : null,
      onTap: onTap,
    );
  }
}
