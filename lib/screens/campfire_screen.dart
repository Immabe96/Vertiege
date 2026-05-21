import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:livekit_client/livekit_client.dart';
import '../state/resident_provider.dart';
import '../state/voice_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/profile/cosmetic_avatar.dart';

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
    final resident = ref.read(residentProvider).resident;
    if (resident != null) {
      ref
          .read(voiceProvider.notifier)
          .joinCampfire(
            channelId: widget.channelId,
            channelName: widget.channelName,
            residentId: resident.id,
            residentName: resident.name,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);
    final participants = voiceState.participants;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.channelName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.bold,
                color: VColors.warning,
              ),
            ),
            Text(
              widget.worldName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: VSpacing.xl),
          Expanded(
            child: participants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 64,
                          color: VColors.warning,
                        ),
                        const SizedBox(height: VSpacing.lg),
                        Text(
                          'Waiting for others to join...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(VSpacing.md),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: VSpacing.sm,
                          crossAxisSpacing: VSpacing.sm,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: participants.length,
                    itemBuilder: (_, i) =>
                        _ParticipantTile(participant: participants[i]),
                  ),
          ),
          const _CampfireControls(),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatefulWidget {
  final Participant participant;
  const _ParticipantTile({required this.participant});

  @override
  State<_ParticipantTile> createState() => _ParticipantTileState();
}

class _ParticipantTileState extends State<_ParticipantTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSpeaking = widget.participant.isSpeaking;
    final isMuted = !widget.participant.isMicrophoneEnabled();
    final identity = widget.participant.identity;
    final name = widget.participant.name.isNotEmpty
        ? widget.participant.name
        : identity;

    return Container(
      padding: const EdgeInsets.all(VSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? VColors.surfaceContainerDark
            : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: isSpeaking
            ? null
            : Border.all(
                color: isDark
                    ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                    : VColors.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
        boxShadow: isSpeaking
            ? [
                BoxShadow(
                  color: VColors.success.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: isSpeaking
          ? AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: VColors.success.withValues(
                        alpha: _pulseAnimation.value,
                      ),
                      width: 2 + (_pulseAnimation.value * 2),
                    ),
                    borderRadius: BorderRadius.circular(VRadius.lg),
                  ),
                  padding: const EdgeInsets.all(VSpacing.sm),
                  child: _ParticipantContent(
                    isMuted: isMuted,
                    name: name,
                    theme: theme,
                    isDark: isDark,
                  ),
                );
              },
            )
          : _ParticipantContent(
              isMuted: isMuted,
              name: name,
              theme: theme,
              isDark: isDark,
            ),
    );
  }
}

class _ParticipantContent extends StatelessWidget {
  final bool isMuted;
  final String name;
  final ThemeData theme;
  final bool isDark;

  const _ParticipantContent({
    required this.isMuted,
    required this.name,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CosmeticAvatar(imageUrl: null, size: 56),
            if (isMuted)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: VColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_off,
                    size: 12,
                    color: VColors.onPrimary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: VSpacing.xs),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _CampfireControls extends ConsumerWidget {
  const _CampfireControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceProvider);
    final notifier = ref.read(voiceProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.xl,
        vertical: VSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? VColors.surfaceContainerDark
            : VColors.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: isDark
                ? VColors.outlineVariantDark
                : VColors.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: voiceState.isMuted ? Icons.mic_off : Icons.mic,
            label: voiceState.isMuted ? 'Unmute' : 'Mute',
            active: !voiceState.isMuted,
            onTap: () => notifier.toggleMute(),
          ),
          _ControlButton(
            icon: voiceState.isDeafened
                ? Icons.hearing_disabled
                : Icons.hearing,
            label: voiceState.isDeafened ? 'Undeafen' : 'Deafen',
            active: !voiceState.isDeafened,
            onTap: () => notifier.toggleDeafen(),
          ),
          _ControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            active: false,
            color: VColors.error,
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
  final Color? color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.active,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? (active ? VColors.primary : (theme.brightness == Brightness.dark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant));
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: c, size: VIconSize.lg),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}
