import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/search_navigation.dart';
import 'v_member_list_sheet.dart';
import '../../router/world_navigation.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/ui.dart';

/// Channel metadata and quick actions (open world, search).
void showChannelDetailsSheet(
  BuildContext context, {
  required String worldId,
  required String channelId,
  required String channelName,
  required String worldName,
  required int activeResidentCount,
  int pinnedCount = 0,
}) {
  showVSheet(
    context,
    _ChannelDetailsContent(
      worldId: worldId,
      channelId: channelId,
      channelName: channelName,
      worldName: worldName,
      activeResidentCount: activeResidentCount,
      pinnedCount: pinnedCount,
    ),
    maxSize: 0.55,
  );
}

class _ChannelDetailsContent extends StatelessWidget {
  final String worldId;
  final String channelId;
  final String channelName;
  final String worldName;
  final int activeResidentCount;
  final int pinnedCount;

  const _ChannelDetailsContent({
    required this.worldId,
    required this.channelId,
    required this.channelName,
    required this.worldName,
    required this.activeResidentCount,
    required this.pinnedCount,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final residentLabel = activeResidentCount == 1 ? 'resident' : 'residents';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.md,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            channelName,
            style: TextStyle(
              fontSize: VFontSize.headlineMd,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimaryOf(brightness),
              height: VLineHeight.headline,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            worldName,
            style: TextStyle(
              fontSize: VFontSize.bodyMd,
              color: VCommuneColors.headerSecondaryOf(brightness),
              height: VLineHeight.body,
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          _InfoRow(
            icon: VIcons.activity,
            label:
                '$activeResidentCount active $residentLabel in channel',
          ),
          if (pinnedCount > 0) ...[
            const SizedBox(height: VSpacing.sm),
            _InfoRow(
              icon: VIcons.pin,
              label:
                  '$pinnedCount pinned ${pinnedCount == 1 ? 'message' : 'messages'}',
            ),
          ],
          const SizedBox(height: VSpacing.lg),
          Divider(color: VCommuneColors.dividerOf(brightness), height: 1),
          const SizedBox(height: VSpacing.sm),
          VTile(
            prefix: Icon(
              VIcons.globe,
              color: VCommuneColors.textNormalOf(brightness),
            ),
            title: const Text('Open world'),
            subtitle: Text(worldName),
            onPress: () {
              Navigator.of(context).pop();
              context.push(exploreWorldPath(worldId));
            },
          ),
          VTile(
            prefix: Icon(
              VIcons.search,
              color: VCommuneColors.textNormalOf(brightness),
            ),
            title: const Text('Search in channel'),
            subtitle: Text('Messages in #$channelName'),
            onPress: () {
              Navigator.of(context).pop();
              openChannelSearch(
                context,
                worldId: worldId,
                channelId: channelId,
                channelName: channelName,
              );
            },
          ),
          VTile(
            prefix: Icon(
              VIcons.users,
              color: VCommuneColors.textNormalOf(brightness),
            ),
            title: const Text('Residents'),
            subtitle: const Text('View list · tap to message'),
            onPress: () {
              Navigator.of(context).pop();
              showResidentListSheet(
                context,
                worldId: worldId,
                channelName: channelName,
              );
            },
          ),
        ],
      ),
    );
  }

}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        Icon(
          icon,
          size: VIconSize.md,
          color: VCommuneColors.textMutedOf(brightness),
        ),
        const SizedBox(width: VSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: VFontSize.bodyMd,
              color: VCommuneColors.textNormalOf(brightness),
              height: VLineHeight.body,
            ),
          ),
        ),
      ],
    );
  }
}
