import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/channel.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../core/empty_state.dart';

class WorldChannelList extends ConsumerStatefulWidget {
  final String worldId;

  const WorldChannelList({super.key, required this.worldId});

  @override
  ConsumerState<WorldChannelList> createState() => _WorldChannelListState();
}

class _WorldChannelListState extends ConsumerState<WorldChannelList> {
  final Map<String, bool> _wardExpanded = {};

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
    final theme = Theme.of(context);

    if (channels.isEmpty) {
      return const AppEmptyState(
        title: 'No channels yet',
        description: 'This world does not have a public channel available.',
        icon: Icons.forum_outlined,
        variant: EmptyStateVariant.default_,
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
    final expanded = _wardExpanded[wardId] ?? true;
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _wardExpanded[wardId] = !expanded),
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
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: IconSizes.sm,
                  color: AppColors.inkMuted,
                ),
                const SizedBox(width: Spacing.xs),
                Text(
                  wardName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: FontSizes.labelSm,
                    fontWeight: FontWeights.semiBold,
                    color: AppColors.inkSecondary,
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

    return ListTile(
      dense: true,
      leading: Icon(
        _icon,
        size: 20,
        color: unreadCount > 0
            ? AppColors.ink
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
                color: AppColors.error,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeights.bold,
                  color: Colors.white,
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
