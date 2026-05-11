import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:livekit_client/livekit_client.dart';
import '../state/resident_provider.dart';
import '../state/voice_provider.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';
import '../widgets/core/glass_panel.dart';
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
      ref.read(voiceProvider.notifier).joinCampfire(
        channelId: widget.channelId,
        channelName: widget.channelName,
        residentId: resident.id,
        residentName: resident.name,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);
    final participants = voiceState.participants;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏕️ ${widget.channelName}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: FontSizes.headlineMd,
                fontWeight: FontWeights.bold,
                color: AppColors.warning,
              ),
            ),
            Text(
              widget.worldName,
              style: const TextStyle(
                fontSize: FontSizes.labelSm,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: Spacing.xl),
          // Participant grid
          Expanded(
            child: participants.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department, size: 64, color: AppColors.warning),
                        const SizedBox(height: Spacing.lg),
                        Text(
                          'Waiting for others to join...',
                          style: GoogleFonts.inter(
                            fontSize: FontSizes.bodyMd,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(Spacing.md),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: Spacing.sm,
                      crossAxisSpacing: Spacing.sm,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: participants.length,
                    itemBuilder: (_, i) => _ParticipantTile(participant: participants[i]),
                  ),
          ),

          // Control bar
          const _CampfireControls(),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final Participant participant;
  const _ParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    final isSpeaking = participant.isSpeaking;
    final isMuted = !participant.isMicrophoneEnabled();
    final identity = participant.identity;
    final name = participant.name.isNotEmpty ? participant.name : identity;

    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isSpeaking)
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success,
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              CosmeticAvatar(imageUrl: null, size: 56),
              if (isMuted)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_off, size: 12, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: FontSizes.labelSm,
              color: AppColors.ink,
            ),
          ),
        ],
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

    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xl, vertical: Spacing.lg),
      borderRadius: BorderRadius.zero,
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
            icon: voiceState.isDeafened ? Icons.hearing_disabled : Icons.hearing,
            label: voiceState.isDeafened ? 'Undeafen' : 'Deafen',
            active: !voiceState.isDeafened,
            onTap: () => notifier.toggleDeafen(),
          ),
          _ControlButton(
            icon: Icons.call_end,
            label: 'Leave',
            active: false,
            color: AppColors.error,
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
    final c = color ?? (active ? AppColors.primary : AppColors.inkMuted);
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
            child: Icon(icon, color: c, size: IconSizes.lg),
          ),
          const SizedBox(height: Spacing.xs),
          Text(label, style: TextStyle(fontSize: FontSizes.labelSm, color: c)),
        ],
      ),
    );
  }
}
