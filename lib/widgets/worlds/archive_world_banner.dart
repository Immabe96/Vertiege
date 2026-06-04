import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Read-only banner for archived dominion worlds (Wave 17).
class ArchiveWorldBanner extends StatelessWidget {
  const ArchiveWorldBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        VSpacing.md,
        VSpacing.sm,
        VSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLow.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: VColors.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: VColors.outline),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Text(
              'This world is archived — browse only. Manage tools stay available to council.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
