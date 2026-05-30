import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/contextual_help_prefs.dart';
import '../../theme/v_context_colors.dart';
import '../../theme/v_tokens.dart';
import '../core/progression_help_button.dart';
import '../../config/progression_glossary.dart';

/// Achievement-first context line at the top of Nexus.
class NexusContextStrip extends StatelessWidget {
  final bool showJoinWorldsCta;

  const NexusContextStrip({
    super.key,
    this.showJoinWorldsCta = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nexus',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: VFontWeight.semiBold,
              color: context.vOnSurface,
            ),
          ),
          FutureBuilder<bool>(
            future: ContextualHelpPrefs.shouldShowContextualHelp(),
            builder: (context, snapshot) {
              if (snapshot.data != true) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: VSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          showJoinWorldsCta
                              ? 'Join a world to unlock your feed and submit proof.'
                              : 'Your worlds, quests, and progress — start here.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.vOnSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                      ProgressionHelpButton(
                        focus: ProgressionFocus.overview,
                        tooltip: 'How XP, tier & rep work',
                        iconSize: VIconSize.md,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          if (showJoinWorldsCta) ...[
            const SizedBox(height: VSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/explore'),
                icon: const Icon(Icons.explore_outlined, size: VIconSize.sm),
                label: const Text('Browse worlds'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
