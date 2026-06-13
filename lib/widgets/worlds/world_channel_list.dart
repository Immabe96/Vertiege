import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/channel.dart';
import '../../models/channel_mute_mode.dart';
import '../../models/resident.dart';
import '../../models/world.dart';
import '../../router/world_navigation.dart';
import '../../services/voice_presence_service.dart';
import '../../services/world_channel_access_service.dart';
import '../../state/channel_provider.dart';
import '../../state/chat_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/empty_state.dart';

/// Prefetch off-screen channel rows (DCX-127).
const double kChannelListCacheExtent = 320;

class WorldChannelList extends ConsumerStatefulWidget {
  final String worldId;

  const WorldChannelList({super.key, required this.worldId});

  @override
  ConsumerState<WorldChannelList> createState() => _WorldChannelListState();
}

class _WorldChannelListState extends ConsumerState<WorldChannelList> {
  Map<String, bool> _wardExpanded = {};
  String? _lastActivityKey;
  Map<String, int> _voiceOccupancy = {};

  static const String _prefsKey = 'ward_collapsed_state';

  @override
  void initState() {
    super.initState();
    _loadCollapsedState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final residentId = ref.read(residentProvider).resident?.id;
      if (residentId != null) {
        ref.read(chatProvider.notifier).loadChannelMutePrefs(residentId);
      }
    });
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
  String? _lastVoiceKey;

  Future<void> _loadVoiceOccupancy(List<String> channelIds) async {
    final next = <String, int>{};
    for (final id in channelIds) {
      next[id] = await VoicePresenceService.occupancy(id);
    }
    if (!mounted) return;
    setState(() => _voiceOccupancy = next);
  }

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

  List<_ChannelListRow> _buildRows({
    required List<WorldChannel> channels,
    required World? world,
    required WorldFeatures features,
    required Resident? resident,
  }) {
    final rows = <_ChannelListRow>[_ChannelListHeaderRow()];
    final ungrouped = channels.where((c) => c.wardId == null).toList();
    final wardMap = <String, List<WorldChannel>>{};
    for (final c in channels) {
      if (c.wardId != null) {
        wardMap.putIfAbsent(c.wardId!, () => []).add(c);
      }
    }

    for (final entry in wardMap.entries) {
      final wardId = entry.key;
      final wardName = entry.value.first.wardName ?? wardId;
      rows.add(_WardHeaderRow(wardId: wardId, wardName: wardName));
      if (_isExpanded(wardId)) {
        for (final ch in entry.value) {
          rows.add(
            _ChannelRow(
              channel: ch,
              world: world,
              features: features,
              resident: resident,
              voiceOccupancy: ch.channelType == ChannelType.voice
                  ? _voiceOccupancy[ch.id]
                  : null,
            ),
          );
        }
      }
    }

    for (final ch in ungrouped) {
      rows.add(
        _ChannelRow(
          channel: ch,
          world: world,
          features: features,
          resident: resident,
          voiceOccupancy: ch.channelType == ChannelType.voice
              ? _voiceOccupancy[ch.id]
              : null,
        ),
      );
    }

    if (resident?.id == world?.sovereignId) {
      rows.add(const _CreateChannelRow());
    }
    return rows;
  }

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
    final voiceIds = channels
        .where((c) => c.channelType == ChannelType.voice)
        .map((c) => c.id)
        .toList();
    final voiceKey = voiceIds.join('|');
    if (voiceKey.isNotEmpty && voiceKey != _lastVoiceKey) {
      _lastVoiceKey = voiceKey;
      Future.microtask(() => _loadVoiceOccupancy(voiceIds));
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

    final rows = _buildRows(
      channels: channels,
      world: world,
      features: features,
      resident: resident,
    );

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: VSpacing.md),
      cacheExtent: kChannelListCacheExtent,
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        return switch (row) {
          _ChannelListHeaderRow() => Padding(
            padding: const EdgeInsets.only(
              top: VSpacing.sm,
              bottom: VSpacing.xs,
              left: VSpacing.lg,
              right: VSpacing.lg,
            ),
            child: Text(
              'Channels',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: VFontWeight.bold,
              ),
            ),
          ),
          _WardHeaderRow(:final wardId, :final wardName) => _WardHeader(
            wardId: wardId,
            wardName: wardName,
            expanded: _isExpanded(wardId),
            onToggle: () => _toggleWard(wardId),
          ),
          _ChannelRow(
            :final channel,
            :final world,
            :final features,
            :final resident,
            :final voiceOccupancy,
          ) =>
            _buildChannelTile(
              channel,
              world,
              features,
              resident,
              voiceOccupancy: voiceOccupancy,
            ),
          _CreateChannelRow() => _CreateChannelRowWidget(
            onTap: () => context.push(worldSettingsPath(widget.worldId)),
          ),
        };
      },
    );
  }

  Widget _buildChannelTile(
    WorldChannel channel,
    World? world,
    WorldFeatures features,
    Resident? resident, {
    int? voiceOccupancy,
  }) {
    final decision = world == null
        ? const ChannelAccessDecision.locked('World unavailable.')
        : WorldChannelAccessService.decision(
            world: world,
            channel: channel,
            features: features,
            resident: resident,
          );
    final muteMode = ref.watch(
      chatProvider.select((s) => s.muteModeFor(channel.id)),
    );
    return _ChannelTile(
      channel: channel,
      voiceOccupancy: voiceOccupancy,
      unreadCount: decision.canOpen && channel.channelType != ChannelType.voice
          ? ref.read(chatProvider.notifier).unreadCount(
                channel.id,
                currentUserId: resident?.id,
              )
          : 0,
      isMuted: muteMode != ChannelMuteMode.off,
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
}

sealed class _ChannelListRow {
  const _ChannelListRow();
}

final class _ChannelListHeaderRow extends _ChannelListRow {
  const _ChannelListHeaderRow();
}

final class _WardHeaderRow extends _ChannelListRow {
  final String wardId;
  final String wardName;
  const _WardHeaderRow({required this.wardId, required this.wardName});
}

final class _ChannelRow extends _ChannelListRow {
  final WorldChannel channel;
  final World? world;
  final WorldFeatures features;
  final Resident? resident;
  final int? voiceOccupancy;
  const _ChannelRow({
    required this.channel,
    required this.world,
    required this.features,
    required this.resident,
    this.voiceOccupancy,
  });
}

final class _CreateChannelRow extends _ChannelListRow {
  const _CreateChannelRow();
}

class _WardHeader extends StatelessWidget {
  final String wardId;
  final String wardName;
  final bool expanded;
  final VoidCallback onToggle;

  const _WardHeader({
    required this.wardId,
    required this.wardName,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      button: true,
      expanded: expanded,
      label: '$wardName category',
      child: GestureDetector(
        onTap: onToggle,
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
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final WorldChannel channel;
  final int unreadCount;
  final int? voiceOccupancy;
  final bool isMuted;
  final VoidCallback? onTap;
  final String? lockedReason;

  const _ChannelTile({
    required this.channel,
    required this.unreadCount,
    this.voiceOccupancy,
    this.isMuted = false,
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
                size: VIconSize.md,
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
                        if (voiceOccupancy != null && voiceOccupancy! > 0)
                          Text(
                            '$voiceOccupancy in Campfire',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: VColors.warning,
                              fontWeight: VFontWeight.semiBold,
                            ),
                          )
                        else ...[
                          if (isMuted)
                            Padding(
                              padding: const EdgeInsets.only(
                                right: VSpacing.xs,
                              ),
                              child: Icon(
                                Icons.notifications_off_outlined,
                                size: VIconSize.sm,
                                color: theme.colorScheme.onSurfaceVariant,
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

class _CreateChannelRowWidget extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateChannelRowWidget({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.lg,
            VSpacing.xs,
            VSpacing.lg,
            VSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.add,
                size: VIconSize.base,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: VSpacing.sm),
              Text(
                'Create channel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
