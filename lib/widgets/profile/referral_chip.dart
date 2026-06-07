import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/v_feedback.dart';

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
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(VRadius.md),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_alt,
                  size: VIconSize.sm + 2,
                  color: theme.colorScheme.primary,
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
                    color: theme.colorScheme.primary,
                    fontFamily: VFont.mono,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: referralCode));
                    VFeedback.showMessage(context, 'Referral code copied!');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child:  Icon(
                      Icons.copy,
                      size: VIconSize.sm,
                      color: theme.colorScheme.primary,
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
