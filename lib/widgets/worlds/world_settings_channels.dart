import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../../models/channel.dart';
import '../../widgets/core/glass_panel.dart';
import '../../state/channel_provider.dart';
import '../../ui/icons/v_icons.dart';

class WorldSettingsChannels extends ConsumerWidget {
  final String worldId;
  final String? sovereignId;
  final String? residentId;
  final void Function(String channelId, String currentName) onRename;
  final void Function(String channelId, String name) onDelete;
  final void Function(BuildContext context) onCreate;

  const WorldSettingsChannels({
    super.key,
    required this.worldId,
    required this.sovereignId,
    required this.residentId,
    required this.onRename,
    required this.onDelete,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final channels = ref.watch(channelProvider).channelsByWorld[worldId] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.tag,
              color: VColors.tertiary,
              size: IconSizes.sm,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'Channels',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeights.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Text(
          'Manage channels for this world.',
          style: theme.textTheme.bodySmall?.copyWith(color: VColors.outline),
        ),
        const SizedBox(height: Spacing.md),
        if (channels.isNotEmpty)
          ...channels.map(
            (ch) => _ChannelRow(
              channel: ch,
              isSovereign: residentId == sovereignId,
              onRename: () => onRename(ch.id, ch.name),
              onDelete: () => onDelete(ch.id, ch.name),
            ),
          ),
        const SizedBox(height: Spacing.sm),
        if (residentId == sovereignId)
          SizedBox(
            width: double.infinity,
            height: TouchTargets.minimum,
            child: OutlinedButton.icon(
              onPressed: () => onCreate(context),
              icon: const Icon(VIcons.plus, size: 18),
              label: const Text('Add Channel'),
            ),
          ),
      ],
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final WorldChannel channel;
  final bool isSovereign;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _ChannelRow({
    required this.channel,
    required this.isSovereign,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: VSurfacePanel(
        padding: const EdgeInsets.all(Spacing.md),
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
        child: InkWell(
          onTap: channel.isDefault ? null : onRename,
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
          child: Row(
            children: [
              Icon(
                channel.channelType == ChannelType.announcement
                    ? Icons.campaign
                    : channel.channelType == ChannelType.feed
                    ? Icons.dynamic_feed
                    : Icons.tag,
                size: IconSizes.md,
                color: VColors.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '# ${channel.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeights.semiBold,
                        color: VColors.onSurface,
                      ),
                    ),
                    if (channel.description != null &&
                        channel.description!.isNotEmpty)
                      Text(
                        channel.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: VColors.outline,
                        ),
                      ),
                  ],
                ),
              ),
              if (channel.isDefault)
                Text(
                  'Default',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: VColors.outline,
                  ),
                )
              else if (isSovereign)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: VColors.error,
                  ),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
