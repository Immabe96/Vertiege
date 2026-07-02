import 'package:flutter/material.dart';

import '../../theme/v_tokens.dart';

/// Inline hint for tier × standing gates (G3).
class WorldCapabilityHint extends StatelessWidget {
  final String message;
  final IconData icon;

  const WorldCapabilityHint({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.md,
        0,
        VSpacing.md,
        VSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: VIconSize.sm,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: VSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tooltip on icon for compact toolbars.
class WorldCapabilityTooltipIcon extends StatelessWidget {
  final String message;

  const WorldCapabilityTooltipIcon({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      preferBelow: false,
      child: Icon(
        Icons.help_outline,
        size: VIconSize.md,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
