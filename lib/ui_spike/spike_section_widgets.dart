import 'package:flutter/material.dart';

import '../theme/v_tokens.dart';

/// Uppercase section label matching [VSectionList] rhythm.
class SpikeSectionHeader extends StatelessWidget {
  final String title;

  const SpikeSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: VSpacing.xs,
        bottom: VSpacing.xs,
        top: VSpacing.sm,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Card-like group wrapper for M3 / shadcn list sections.
class SpikeSectionGroup extends StatelessWidget {
  final List<Widget> children;

  const SpikeSectionGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}
