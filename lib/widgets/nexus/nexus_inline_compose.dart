import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/resident_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../feed/post_input.dart';

/// Inline Nexus composer in feed header — no floating + (DCX-023).
class NexusInlineCompose extends ConsumerWidget {
  const NexusInlineCompose({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resident = ref.watch(residentProvider).resident;
    final joined = resident?.joinedWorldIds ?? const <String>[];
    if (joined.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.md,
          VSpacing.sm,
          VSpacing.md,
          0,
        ),
        child: Text(
          'Join a world to post to Nexus',
          style: TextStyle(
            fontSize: VFontSize.labelMd,
            color: VCommuneColors.textMuted.withValues(alpha: 0.9),
          ),
        ),
      );
    }

    return ColoredBox(
      color: VCommuneColors.surfaceSecondary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.md,
          VSpacing.sm,
          VSpacing.md,
          VSpacing.xs,
        ),
        child: PostInput(
          worldId: joined.first,
          showWorldSelector: joined.length > 1,
        ),
      ),
    );
  }
}
