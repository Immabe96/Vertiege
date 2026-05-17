import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

class SovereignErrorBanner extends StatelessWidget {
  final String message;
  final String? code;
  final VoidCallback? onRetry;

  const SovereignErrorBanner({
    super.key,
    required this.message,
    this.code,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.marginMobile,
        vertical: Spacing.md,
      ),
      color: (isDark ? VColors.errorContainerDark : VColors.errorContainer).withValues(alpha: 0.8),
      child: SafeArea(
        child: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: isDark ? VColors.onErrorContainerDark : VColors.onErrorContainer,
              size: IconSizes.md,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: FontSizes.labelSm,
                      fontWeight: FontWeights.semiBold,
                      color: isDark ? VColors.onErrorContainerDark : VColors.onErrorContainer,
                    ),
                  ),
                  if (code != null)
                    Text(
                      code!,
                      style: TextStyle(
                        fontSize: FontSizes.labelSm,
              color: isDark ? VColors.onErrorContainerDark : VColors.onErrorContainer,
                      ),
                    ),
                ],
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync,
                      size: IconSizes.sm,
                      color: VColors.tertiary,
                    ),
                    SizedBox(width: Spacing.xs),
                    Text(
                      'RETRY',
                      style: TextStyle(
                        fontSize: FontSizes.labelSm,
                        fontWeight: FontWeights.semiBold,
                      color: VColors.tertiary,
                        letterSpacing: LetterSpacing.label,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
