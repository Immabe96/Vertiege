import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class AuthErrorCard extends StatelessWidget {
  final String message;
  const AuthErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: IconSizes.md),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: FontSizes.labelSm,
                color: AppColors.error,
                fontWeight: FontWeights.regular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
