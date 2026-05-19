import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';

/// Variant determines the color tint applied to the empty state.
enum EmptyStateVariant { default_, error, success }

/// A branded, minimal "no data" widget for Vertiege.
///
/// Displays a subtle icon, title, description, and an optional CTA button.
class AppEmptyState extends StatelessWidget {
  final String title;
  final String? description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EmptyStateVariant variant;

  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.variant = EmptyStateVariant.default_,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color variantColor;
    switch (variant) {
      case EmptyStateVariant.error:
        variantColor = VColors.error;
      case EmptyStateVariant.success:
        variantColor = VColors.success;
      case EmptyStateVariant.default_:
        variantColor = isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? VColors.surfaceContainerHighDark
                    : VColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: VIconSize.xl,
                color: variantColor,
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
            if (description != null) ...[
              const SizedBox(height: VSpacing.sm),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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

/// Convenience widget wrapping [AppEmptyState] for error states.
///
/// Pre-configured with an error icon, "Something went wrong" title,
/// a customizable [message], and a "Retry" button wired to [onRetry].
class AppErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const AppErrorState({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      title: 'Something went wrong',
      description: message ?? 'An unexpected error occurred. Please try again.',
      icon: Icons.error_outline,
      actionLabel: 'Retry',
      onAction: onRetry,
      variant: EmptyStateVariant.error,
    );
  }
}
