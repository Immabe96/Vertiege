import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Google / Apple sign-in row — Apple only on iOS and macOS.
class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({
    super.key,
    required this.isLoading,
    required this.onGoogle,
    required this.onApple,
    this.isDark,
  });

  final bool isLoading;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final bool? isDark;

  static bool get showAppleSignIn {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark =
        isDark ?? theme.brightness == Brightness.dark;
    final dividerColor =
        dark ? VColors.outlineVariantDark : VColors.outlineVariant;
    final mutedColor =
        dark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant;

    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VRadius.md),
      ),
    );

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: dividerColor)),
            const SizedBox(width: VSpacing.md),
            Text(
              'or',
              style: theme.textTheme.labelSmall?.copyWith(color: mutedColor),
            ),
            const SizedBox(width: VSpacing.md),
            Expanded(child: Divider(color: dividerColor)),
          ],
        ),
        const SizedBox(height: VSpacing.md),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onGoogle,
          icon: const Icon(Icons.g_mobiledata, size: VIconSize.lg),
          label: const Text('Continue with Google'),
          style: buttonStyle,
        ),
        if (showAppleSignIn) ...[
          const SizedBox(height: VSpacing.sm),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onApple,
            icon: const Icon(Icons.apple, size: VIconSize.lg),
            label: const Text('Continue with Apple'),
            style: buttonStyle,
          ),
        ],
      ],
    );
  }
}
