import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
import 'package:livekit_client/livekit_client.dart';
import '../models/channel.dart';
import '../router/world_navigation.dart';
import '../state/channel_provider.dart';
import '../state/resident_provider.dart';
import '../state/voice_provider.dart';
import '../theme/prestige_noir.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/v_accessible.dart';
import '../services/device_permission_service.dart';
import '../widgets/voice/campfire_reconnect_banner.dart';

class CampfireScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String channelName;
  final String worldId;
  final String worldName;

  const CampfireScreen({
    super.key,
    required this.channelId,
    required this.channelName,
    required this.worldId,
    required this.worldName,
  });

  @override
  ConsumerState<CampfireScreen> createState() => _CampfireScreenState();
}

class _CampfireScreenState extends ConsumerState<CampfireScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _joinWithMicPermission(),
    );
  }

  Future<void> _joinWithMicPermission() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null || !mounted) return;

    final micOk = await DevicePermissionService.requestMicrophoneWithRationale(
      context,
    );
    if (!micOk || !mounted) {
      ref.read(voiceProvider.notifier).leaveCampfire();
      return;
    }

    await ref
        .read(voiceProvider.notifier)
        .joinCampfire(
          channelId: widget.channelId,
          channelName: widget.channelName,
          residentId: resident.id,
          residentName: resident.name,
          worldId: widget.worldId,
          worldName: widget.worldName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);
    final participants = voiceState.participants;
    final resident = ref.watch(residentProvider).resident;
    final theme = Theme.of(context);
    final anyoneSpeaking = participants.any((p) => p.isSpeaking);

    return VScaffold(
      header: VNestedHeader(
        prefixes: [
          VAccessibleHeaderAction(
            label: 'Leave voice channel',
            icon: const Icon(VIcons.chevronLeft),
            onPress: () {
              if (context.canPop()) context.pop();
            },
          ),
        ],
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.channelName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.bold,
                color: PrestigeNoir.foreground,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              voiceState.isConnected
                  ? '${participants.length} listening · ${widget.worldName}'
                  : widget.worldName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: PrestigeNoir.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      child: ColoredBox(
        color: PrestigeNoir.bg,
        child: Column(
          children: [
            const CampfireReconnectBanner(),
            if (voiceState.isConnected && !voiceState.isConnecting)
              _VoiceVisualizer(active: anyoneSpeaking),
            Expanded(
              child: resident == null
                  ? const AppEmptyState(
                      title: 'Sign in to join Campfire',
                      description:
                          'Voice rooms are reserved for eligible residents.',
                      icon: Icons.lock_outline,
                    )
                  : voiceState.error != null
                  ? AppEmptyState(
                      title: 'Could not join Campfire',
                      description: voiceState.error,
                      icon: Icons.volume_off_outlined,
                      variant: EmptyStateVariant.error,
                    )
                  : voiceState.isConnecting
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VSpinner(size: 32, color: VColors.brand),
                          const SizedBox(height: VSpacing.lg),
                          Text(
                            'Joining Campfire...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: PrestigeNoir.muted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : participants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 64,
                            color: VColors.brand.withValues(alpha: 0.85),
                          ),
                          const SizedBox(height: VSpacing.lg),
                          Text(
                            'Waiting for others to join...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: PrestigeNoir.muted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              VSpacing.md,
                              VSpacing.md,
                              VSpacing.md,
                              VSpacing.sm,
                            ),
                            child: Text(
                              'IN VOICE · ${participants.length}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: PrestigeNoir.muted,
                                fontWeight: VFontWeight.semiBold,
                                letterSpacing: 0.8,
                                fontSize: VFontSize.labelSm,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VSpacing.md,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.6,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _VoiceParticipantTile(
                                participant: participants[i],
                              ),
                              childCount: participants.length,
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: VSpacing.md),
                        ),
                      ],
                    ),
            ),
            _CampfireTextSplitBar(
              worldId: widget.worldId,
              worldName: widget.worldName,
            ),
            const _CampfireControls(),
          ],
        ),
      ),
    );
  }
}

/// Animated gold bar visualizer (Open Design campfire.html).
class _VoiceVisualizer extends StatefulWidget {
  final bool active;

  const _VoiceVisualizer({required this.active});

  @override
  State<_VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<_VoiceVisualizer>
    with SingleTickerProviderStateMixin {
  static const _barHeights = <double>[
    24, 40, 32, 52, 20, 48, 36, 28, 44, 18, 38, 30, 46, 22, 42,
  ];

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _VoiceVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active) {
      _controller.stop();
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0B0D),
        border: Border(bottom: BorderSide(color: PrestigeNoir.border)),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_barHeights.length, (i) {
              final base = _barHeights[i];
              final phase = (i * 0.1) % 1.0;
              final pulse = reduceMotion || !widget.active
                  ? 0.75
                  : 0.7 + 0.3 * ((_controller.value + phase) % 1.0);
              final height = base * pulse;
              final isPeak = i == 3 || i == 5 || i == 12;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 4,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isPeak
                          ? [
                              VColors.brand,
                              VColors.warning.withValues(alpha: 0.5),
                            ]
                          : [
                              VColors.brand,
                              VColors.brand.withValues(alpha: 0.14),
                            ],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _VoiceParticipantTile extends StatefulWidget {
  final Participant participant;

  const _VoiceParticipantTile({required this.participant});

  @override
  State<_VoiceParticipantTile> createState() => _VoiceParticipantTileState();
}

class _VoiceParticipantTileState extends State<_VoiceParticipantTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _ringOpacity = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  Color _avatarTint(String seed) {
    final palette = [
      (VColors.brand.withValues(alpha: 0.14), VColors.brand),
      (VColors.success.withValues(alpha: 0.2), VColors.success),
      (VColors.warning.withValues(alpha: 0.2), VColors.warning),
      (VColors.error.withValues(alpha: 0.2), VColors.error),
    ];
    return palette[seed.hashCode.abs() % palette.length].$1;
  }

  Color _avatarFg(String seed) {
    final palette = [
      VColors.brand,
      VColors.success,
      VColors.warning,
      VColors.error,
    ];
    return palette[seed.hashCode.abs() % palette.length];
  }

  String _statusLabel(bool isSpeaking, bool isMuted) {
    if (isSpeaking) return 'Speaking';
    if (isMuted) return 'Muted';
    return 'Listening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSpeaking = widget.participant.isSpeaking;
    final isMuted = !widget.participant.isMicrophoneEnabled();
    final identity = widget.participant.identity;
    final name = widget.participant.name.isNotEmpty
        ? widget.participant.name
        : identity;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return AnimatedBuilder(
      animation: _ringOpacity,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.sm + 2,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: PrestigeNoir.surfaceRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSpeaking ? VColors.success : PrestigeNoir.borderLight,
              width: 1,
            ),
            boxShadow: isSpeaking
                ? [
                    BoxShadow(
                      color: VColors.success.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isSpeaking)
                AnimatedBuilder(
                  animation: _ringOpacity,
                  builder: (_, child) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: VColors.success.withValues(
                          alpha: _ringOpacity.value,
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _avatarTint(name),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: VFontWeight.bold,
                    color: _avatarFg(name),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: VFontWeight.semiBold,
                    color: PrestigeNoir.foreground,
                    fontSize: 13,
                  ),
                ),
                Text(
                  _statusLabel(isSpeaking, isMuted),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: PrestigeNoir.muted,
                    fontSize: VFontSize.labelSm,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isMuted ? Icons.mic_off_outlined : Icons.mic_none_outlined,
            size: 20,
            color: isMuted ? VColors.error : PrestigeNoir.muted,
          ),
        ],
      ),
    );
  }
}

/// Picture-in-picture style bar to read text while in Campfire (DCX-142).
class _CampfireTextSplitBar extends ConsumerWidget {
  final String worldId;
  final String worldName;

  const _CampfireTextSplitBar({
    required this.worldId,
    required this.worldName,
  });

  WorldChannel? _textChannel(List<WorldChannel> channels) {
    for (final name in ['general', 'lounge', 'chat']) {
      final match = channels
          .where(
            (c) =>
                c.channelType == ChannelType.text &&
                c.name.toLowerCase() == name,
          )
          .firstOrNull;
      if (match != null) return match;
    }
    return channels
        .where((c) => c.channelType == ChannelType.text)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channels = ref.watch(channelProvider).channelsByWorld[worldId] ?? [];
    final textChannel = _textChannel(channels);
    if (textChannel == null) return const SizedBox.shrink();

    return Material(
      color: const Color(0xFF0E1013),
      child: InkWell(
        onTap: () => context.push(
          worldChannelPath(worldId, textChannel),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: PrestigeNoir.border)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.forum_outlined,
                size: VIconSize.sm,
                color: VColors.brand,
              ),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: Text(
                  'Read #${textChannel.name} while in Campfire',
                  style: const TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.medium,
                    color: PrestigeNoir.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: VIconSize.denseSm,
                color: PrestigeNoir.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampfireControls extends ConsumerWidget {
  const _CampfireControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceProvider);
    final notifier = ref.read(voiceProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.md,
        vertical: VSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0E11),
        border: Border(top: BorderSide(color: PrestigeNoir.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: voiceState.isMuted ? Icons.mic_off : Icons.mic,
            label: voiceState.isMuted ? 'Unmute' : 'Mic',
            active: !voiceState.isMuted,
            onTap: notifier.toggleMute,
          ),
          _ControlButton(
            icon: voiceState.isDeafened
                ? Icons.hearing_disabled
                : Icons.hearing,
            label: voiceState.isDeafened ? 'Undeafen' : 'Deafen',
            active: !voiceState.isDeafened,
            onTap: notifier.toggleDeafen,
          ),
          _ControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            danger: true,
            onTap: () {
              notifier.leaveCampfire();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool danger;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.active = false,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = danger
        ? VColors.error.withValues(alpha: 0.2)
        : (active ? PrestigeNoir.accentSoft : PrestigeNoir.surfaceRaised);
    final iconBorder = danger
        ? VColors.error
        : (active ? VColors.brand : PrestigeNoir.border);
    final iconColor = danger
        ? VColors.error
        : (active ? VColors.brand : PrestigeNoir.muted);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: iconBorder),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: PrestigeNoir.muted,
              fontSize: VFontSize.labelSm,
            ),
          ),
        ],
      ),
    );
  }
}
