import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';

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
        horizontal: VSpacing.lg,
        vertical: VSpacing.md,
      ),
      color: (isDark ? VColors.errorContainerDark : VColors.errorContainer).withValues(alpha: 0.8),
      child: SafeArea(
        child: Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: isDark ? VColors.onErrorContainerDark : VColors.onErrorContainer,
              size: VIconSize.md,
            ),
            const SizedBox(width: VSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.semiBold,
                      color: isDark ? VColors.onErrorContainerDark : VColors.onErrorContainer,
                    ),
                  ),
                  if (code != null)
                    Text(
                      code!,
                      style: TextStyle(
                        fontSize: VFontSize.labelSm,
              color: isDark ? VColors.onErrorContainerDark : VColors.onErrorContainer,
                      ),
                    ),
                ],
              ),
            ),
            if (onRetry != null)
              VButton(
                label: 'RETRY',
                onPressed: onRetry,
                icon: const Icon(
                  Icons.sync,
                  size: VIconSize.sm,
                  color: VColors.tertiary,
                ),
                variant: ButtonVariant.text,
              ),
          ],
        ),
      ),
    );
  }
}
