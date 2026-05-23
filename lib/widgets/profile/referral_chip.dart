import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class ReferralChip extends StatelessWidget {
  final String referralCode;
  final String? referredBy;

  const ReferralChip({super.key, required this.referralCode, this.referredBy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.lg,
              vertical: VSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: VColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(VRadius.md),
              border: Border.all(
                color: VColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_alt,
                  size: VIconSize.sm + 2,
                  color: VColors.primary,
                ),
                const SizedBox(width: VSpacing.sm),
                Text(
                  'YOUR REFERRAL CODE: ',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: VColors.outline,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  referralCode,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: VFontWeight.bold,
                    color: VColors.primary,
                    fontFamily: VFont.mono,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
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
                      color: VColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: const Icon(
                      Icons.copy,
                      size: VIconSize.sm,
                      color: VColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (referredBy != null && referredBy!.isNotEmpty) ...[
            const SizedBox(height: VSpacing.sm),
            Text(
              'Referred by: $referredBy',
              style: theme.textTheme.labelSmall?.copyWith(
                color: VColors.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
