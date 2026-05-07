import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

class ReferralChip extends StatelessWidget {
  final String referralCode;
  final String? referredBy;

  const ReferralChip({super.key, required this.referralCode, this.referredBy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_alt, size: IconSizes.sm + 2, color: AppColors.primary),
                const SizedBox(width: Spacing.sm),
                Text(
                  'YOUR REFERRAL CODE: ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.inkMuted,
                    letterSpacing: LetterSpacing.label,
                  ),
                ),
                Text(
                  referralCode,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeights.bold,
                    color: AppColors.primary,
                    fontFamily: AppFont.mono,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral code copied!')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                    ),
                    child: const Icon(Icons.copy, size: IconSizes.sm, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          if (referredBy != null && referredBy!.isNotEmpty) ...[
            const SizedBox(height: Spacing.sm),
            Text(
              'Referred by: $referredBy',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.inkMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
