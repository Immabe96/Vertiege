import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/world_navigation.dart';
import '../../state/voice_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Compact Campfire status while connected or connecting — no full-screen chrome.
class CampfireMiniBar extends ConsumerWidget {
  const CampfireMiniBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voice = ref.watch(voiceProvider);
    if (voice.activeCampfireId == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    final status = _statusLine(voice);
    final dotColor = voice.isConnected
        ? VColors.success
        : voice.isConnecting
            ? VColors.warning
            : VColors.error;

    return Positioned(
      top: VSpacing.xl,
      left: VSpacing.lg,
      right: VSpacing.lg,
      child: SafeArea(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.md,
              vertical: VSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: VColors.surfaceContainerDark,
              borderRadius: BorderRadius.circular(VRadius.pill),
              border: Border.all(color: VColors.outlineVariantDark),
              boxShadow: VShadow.lg,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: voice.isConnected
                      ? () {
                          final id = voice.activeCampfireId;
                          if (id == null) return;
                          context.push(
                            campfirePath(
                              channelId: id,
                              name: voice.activeCampfireName ?? 'Campfire',
                              worldId: voice.activeWorldId,
                              worldName: voice.activeWorldName,
                            ),
                          );
                        }
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: VSpacing.sm),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          voice.activeCampfireName ?? 'Campfire',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: VFontWeight.semiBold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: Text(
                    status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: VColors.onSurfaceVariantDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (voice.isConnected) ...[
                  IconButton(
                    tooltip: voice.isMuted ? 'Unmute' : 'Mute',
                    icon: Icon(
                      voice.isMuted ? Icons.mic_off : Icons.mic,
                      size: VIconSize.sm,
                    ),
                    onPressed: () =>
                        ref.read(voiceProvider.notifier).toggleMute(),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: VTouchTarget.iconButton,
                      minHeight: VTouchTarget.iconButton,
                    ),
                  ),
                ],
                IconButton(
                  tooltip: 'Leave Campfire',
                  icon: const Icon(
                    Icons.call_end,
                    size: VIconSize.sm,
                    color: VColors.error,
                  ),
                  onPressed: () =>
                      ref.read(voiceProvider.notifier).leaveCampfire(),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: VTouchTarget.iconButton,
                    minHeight: VTouchTarget.iconButton,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusLine(VoiceState voice) {
    if (voice.isConnecting) return 'Connecting…';
    if (!voice.isConnected) {
      return voice.error ?? 'Not connected';
    }
    final parts = <String>[];
    if (voice.isMuted) parts.add('Muted');
    if (voice.isDeafened) parts.add('Deafened');
    final count = voice.participants.length;
    parts.add(count == 1 ? '1 here' : '$count here');
    return parts.join(' · ');
  }
}
