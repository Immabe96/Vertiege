import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../buttons/v_button.dart';

/// Small inline progress spinner — the sanctioned facade for
/// `CircularProgressIndicator` outside `lib/ui/`.
class VSpinner extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const VSpinner({
    super.key,
    this.size = 20,
    this.strokeWidth = 2,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? PrestigeNoir.accent,
      ),
    );
  }
}

class VEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const VEmptyState({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: PrestigeNoir.surfaceRaised,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: VIconSize.xl,
                color: PrestigeNoir.muted,
              ),
            ),
            const SizedBox(height: VSpacing.lg),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: VFontWeight.semiBold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.sm),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: PrestigeNoir.muted,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: VSpacing.lg),
              VButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: ButtonVariant.tonal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class VLoadingState extends StatelessWidget {
  final String? message;

  const VLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VSpinner(size: 32, strokeWidth: 2.5),
          if (message != null) ...[
            const SizedBox(height: VSpacing.md),
            Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: PrestigeNoir.muted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class VErrorState extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onRetry;

  const VErrorState({
    super.key,
    required this.message,
    this.actionLabel = 'Retry',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: VColors.error),
            const SizedBox(height: VSpacing.lg),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: VColors.error),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: VSpacing.lg),
              VButton(
                label: actionLabel ?? 'Retry',
                onPressed: onRetry,
                variant: ButtonVariant.tonal,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
