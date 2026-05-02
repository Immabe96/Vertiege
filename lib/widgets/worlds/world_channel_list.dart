import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/channel.dart';
import '../../state/channel_provider.dart';

class WorldChannelList extends ConsumerWidget {
  final String worldId;

  const WorldChannelList({super.key, required this.worldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelProvider).channelsByWorld[worldId] ?? [];
    final theme = Theme.of(context);

    if (channels.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
          child: Text('Channels', style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          )),
        ),
        ...channels.map((channel) => _ChannelTile(
              channel: channel,
              onTap: () => context.push('/explore/$worldId/${channel.name}'),
            )),
      ],
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final WorldChannel channel;
  final VoidCallback onTap;

  const _ChannelTile({required this.channel, required this.onTap});

  IconData get _icon => switch (channel.channelType) {
        ChannelType.announcement => Icons.campaign,
        ChannelType.feed => Icons.dynamic_feed,
        ChannelType.text => Icons.tag,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      leading: Icon(_icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
      title: Text('# ${channel.name}', style: theme.textTheme.bodyMedium),
      subtitle: channel.description != null
          ? Text(channel.description!, style: theme.textTheme.labelSmall, maxLines: 1)
          : null,
      onTap: onTap,
    );
  }
}
