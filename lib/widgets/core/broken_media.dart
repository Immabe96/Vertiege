import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

class BrokenMediaTile extends StatelessWidget {
  final double? height;
  final String label;

  const BrokenMediaTile({
    super.key,
    this.height,
    this.label = 'Image unavailable',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      decoration: BoxDecoration(
        color: VColors.surfaceBright,
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        border: Border.all(color: VColors.glassBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.outline,
            size: IconSizes.lg,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
