import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/v_context_colors.dart';
import '../../theme/v_tokens.dart';

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
            'Your proof-first home base',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: VFontWeight.semiBold,
              color: context.vOnSurface,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            showJoinWorldsCta
                ? 'Join a world to unlock your feed, submit achievements, and earn reputation.'
                : 'Posts from your worlds, daily quests, and progress — start here each session.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.vOnSurfaceVariant,
              height: 1.4,
            ),
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
