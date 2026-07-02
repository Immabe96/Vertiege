import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_tokens.dart';

/// Google / Apple sign-in row — Apple only on iOS and macOS.
class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({
    super.key,
    required this.isLoading,
    required this.onGoogle,
    required this.onApple,
  });

  final bool isLoading;
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;

  static bool get showAppleSignIn {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider(color: PrestigeNoir.border)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
              child: Text(
                'or continue with',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: PrestigeNoir.mutedDim,
                  fontSize: VFontSize.labelMd,
                ),
              ),
            ),
            const Expanded(child: Divider(color: PrestigeNoir.border)),
          ],
        ),
        const SizedBox(height: VSpacing.md),
        Row(
          children: [
            if (showAppleSignIn) ...[
              Expanded(
                child: _SocialButton(
                  label: 'Apple',
                  icon: Icons.apple,
                  isLoading: isLoading,
                  onPressed: onApple,
                ),
              ),
              const SizedBox(width: VSpacing.md),
            ],
            Expanded(
              child: _SocialButton(
                label: 'Google',
                icon: Icons.g_mobiledata,
                isLoading: isLoading,
                onPressed: onGoogle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PrestigeNoir.surfaceRaised,
      borderRadius: BorderRadius.circular(VRadius.md),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(VRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(VRadius.md),
            border: Border.all(color: PrestigeNoir.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: VIconSize.lg, color: PrestigeNoir.foreground),
              const SizedBox(width: VSpacing.sm),
              Text(
                label,
                style: const TextStyle(
                  fontSize: VFontSize.labelLg,
                  fontWeight: VFontWeight.medium,
                  color: PrestigeNoir.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
