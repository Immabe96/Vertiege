import 'package:flutter/material.dart';
import '../../theme/colors.dart';
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.marginMobile,
        vertical: Spacing.md,
      ),
      color: AppColors.errorContainer.withValues(alpha: 0.8),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.onErrorContainer, size: IconSizes.md),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: FontSizes.labelSm,
                      fontWeight: FontWeights.semiBold,
                      color: AppColors.onErrorContainer,
                    ),
                  ),
                  if (code != null)
                    Text(
                      code!,
                      style: const TextStyle(
                        fontSize: FontSizes.labelSm,
                        color: AppColors.onErrorContainer,
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
                    Icon(Icons.sync, size: IconSizes.sm, color: AppColors.tertiary),
                    SizedBox(width: Spacing.xs),
                    Text(
                      'RETRY',
                      style: TextStyle(
                        fontSize: FontSizes.labelSm,
                        fontWeight: FontWeights.semiBold,
                        color: AppColors.tertiary,
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
