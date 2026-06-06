import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/channel_mute_mode.dart';
import '../../router/search_navigation.dart';
import 'channel_thread_list_sheet.dart';
import 'v_member_list_sheet.dart';
import '../../router/world_navigation.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/ui.dart';

/// Channel metadata and quick actions (open world, search, notifications).
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
    maxSize: 0.62,
  );
}

class _ChannelDetailsContent extends ConsumerStatefulWidget {
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
  ConsumerState<_ChannelDetailsContent> createState() =>
      _ChannelDetailsContentState();
}

class _ChannelDetailsContentState extends ConsumerState<_ChannelDetailsContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final residentId = ref.read(residentProvider).resident?.id;
      if (residentId != null) {
        ref.read(chatProvider.notifier).loadChannelMutePrefs(residentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final resident = ref.watch(residentProvider).resident;
    final muteMode = ref.watch(
      chatProvider.select((s) => s.muteModeFor(widget.channelId)),
    );
    final residentLabel =
        widget.activeResidentCount == 1 ? 'resident' : 'residents';

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
            widget.channelName,
            style: TextStyle(
              fontSize: VFontSize.headlineMd,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimaryOf(brightness),
              height: VLineHeight.headline,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            widget.worldName,
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
                '${widget.activeResidentCount} active $residentLabel in channel',
          ),
          if (widget.pinnedCount > 0) ...[
            const SizedBox(height: VSpacing.sm),
            _InfoRow(
              icon: VIcons.pin,
              label:
                  '${widget.pinnedCount} pinned ${widget.pinnedCount == 1 ? 'message' : 'messages'}',
            ),
          ],
          if (resident != null) ...[
            const SizedBox(height: VSpacing.lg),
            Text(
              'Notifications',
              style: TextStyle(
                fontSize: VFontSize.labelLg,
                fontWeight: VFontWeight.bold,
                color: VCommuneColors.headerPrimaryOf(brightness),
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            ...ChannelMuteMode.values.map(
              (mode) => RadioListTile<ChannelMuteMode>(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: mode,
                groupValue: muteMode,
                title: Text(mode.label),
                subtitle: Text(
                  switch (mode) {
                    ChannelMuteMode.off =>
                      'Receive all channel and mention alerts',
                    ChannelMuteMode.mentionsOnly =>
                      'Only @mentions and @all pings',
                    ChannelMuteMode.all => 'No channel notifications',
                  },
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: VCommuneColors.textMutedOf(brightness),
                  ),
                ),
                onChanged: (value) async {
                  if (value == null) return;
                  await ref.read(chatProvider.notifier).setChannelMuteMode(
                        residentId: resident.id,
                        channelId: widget.channelId,
                        mode: value,
                      );
                },
              ),
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
            subtitle: Text(widget.worldName),
            onPress: () {
              Navigator.of(context).pop();
              context.push(exploreWorldPath(widget.worldId));
            },
          ),
          VTile(
            prefix: Icon(
              Icons.forum_outlined,
              color: VCommuneColors.textNormalOf(brightness),
            ),
            title: const Text('Threads'),
            subtitle: Text('Active threads in #${widget.channelName}'),
            onPress: () {
              Navigator.of(context).pop();
              showChannelThreadListSheet(
                context,
                channelId: widget.channelId,
                channelName: widget.channelName,
                worldId: widget.worldId,
              );
            },
          ),
          VTile(
            prefix: Icon(
              VIcons.search,
              color: VCommuneColors.textNormalOf(brightness),
            ),
            title: const Text('Search in channel'),
            subtitle: Text('Messages in #${widget.channelName}'),
            onPress: () {
              Navigator.of(context).pop();
              openChannelSearch(
                context,
                worldId: widget.worldId,
                channelId: widget.channelId,
                channelName: widget.channelName,
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
                worldId: widget.worldId,
                channelName: widget.channelName,
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
