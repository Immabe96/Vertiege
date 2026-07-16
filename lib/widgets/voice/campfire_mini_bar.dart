// Campfire connected UI — re-export core bar + channel inline variant.
export '../core/campfire_mini_bar.dart' show CampfireMiniBar;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/world_navigation.dart';
import '../../services/feature_flags.dart';
import '../../state/voice_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// Green inline bar above channel composer when connected to Campfire.
class CampfireChannelBar extends ConsumerWidget {
  const CampfireChannelBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!FeatureFlags.campfireEnabled) return const SizedBox.shrink();

    final voice = ref.watch(voiceProvider);
    if (voice.activeCampfireId == null || !voice.isConnected) {
      return const SizedBox.shrink();
    }

    return Material(
      color: VColors.success.withValues(alpha: 0.12),
      child: InkWell(
        onTap: () {
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
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: VColors.success.withValues(alpha: 0.35)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: VColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: VSpacing.sm),
              Expanded(
                child: Text(
                  'Connected to ${voice.activeCampfireName ?? 'Campfire'} — tap to return',
                  style: const TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.medium,
                    color: VCommuneColors.textNormal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: VIconSize.xs,
                color: VColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
