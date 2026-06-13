import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Non-blocking banner when data loaded from cache or sync partially failed.
class SyncWarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const SyncWarningBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: VColors.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(VRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, size: VIconSize.base, color: VColors.warning),
            const SizedBox(width: VSpacing.sm),
            Expanded(
              child: Text(message, style: theme.textTheme.bodySmall),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
