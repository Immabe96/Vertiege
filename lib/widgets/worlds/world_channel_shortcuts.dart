import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/channel.dart';
import '../../router/world_navigation.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Quick links to General and Announcements on the world feed.
class WorldChannelShortcuts extends StatelessWidget {
  final String worldId;
  final List<WorldChannel> channels;

  const WorldChannelShortcuts({
    super.key,
    required this.worldId,
    required this.channels,
  });

  @override
  Widget build(BuildContext context) {
    WorldChannel? general;
    WorldChannel? announcements;
    for (final c in channels) {
      if (c.name == 'general') general = c;
      if (c.channelType == ChannelType.announcement ||
          c.name == 'announcements' ||
          c.name == 'announcement') {
        announcements = c;
      }
    }
    if (general == null && announcements == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    void open(WorldChannel channel) {
      context.push(worldChannelDestinationPath(worldId, channel));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        0,
      ),
      child: Wrap(
        spacing: VSpacing.sm,
        runSpacing: VSpacing.xs,
        children: [
          if (general != null)
            ActionChip(
              avatar: Icon(
                Icons.tag,
                size: VIconSize.sm,
                color: VColors.primary,
              ),
              label: const Text('General'),
              onPressed: () => open(general!),
              backgroundColor: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainerLow,
            ),
          if (announcements != null)
            ActionChip(
              avatar: Icon(
                Icons.campaign_outlined,
                size: VIconSize.sm,
                color: VColors.tertiary,
              ),
              label: const Text('Announcements'),
              onPressed: () => open(announcements!),
              backgroundColor: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainerLow,
            ),
        ],
      ),
    );
  }
}
