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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: VSpacing.lg,
        vertical: VSpacing.md,
      ),
      color: VColors.errorContainerDark.withValues(alpha: 0.8),
      child: SafeArea(
        child: Row(
          children: [
            const Icon(
              Icons.warning_rounded,
              color: VColors.onErrorContainerDark,
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
                    style: const TextStyle(
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.semiBold,
                      color: VColors.onErrorContainerDark,
                    ),
                  ),
                  if (code != null)
                    Text(
                      code!,
                      style: const TextStyle(
                        fontSize: VFontSize.labelSm,
                        color: VColors.onErrorContainerDark,
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
