import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class AuthErrorCard extends StatelessWidget {
  final String message;
  const AuthErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: VColors.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(VRadius.xl),
        border: Border.all(color: VColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: VColors.error,
            size: VIconSize.md,
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: VFontSize.labelSm,
                color: VColors.error,
                fontWeight: VFontWeight.regular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
