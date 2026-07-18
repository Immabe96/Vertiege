import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';

enum AuthPrestigeMode { signIn, signUp }

class AuthPrestigeBrandHeader extends StatelessWidget {
  const AuthPrestigeBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [VColors.brand, VColors.brandLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            l10n.appTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: VFontWeight.extraBold,
              fontSize: 36,
              letterSpacing: -1.1,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.authSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: VFontSize.labelLg,
            color: PrestigeNoir.muted,
          ),
        ),
      ],
    );
  }
}

class AuthPrestigeModeSwitch extends StatelessWidget {
  const AuthPrestigeModeSwitch({
    super.key,
    required this.activeMode,
    required this.isLoading,
    required this.onSignIn,
    required this.onSignUp,
  });

  final AuthPrestigeMode activeMode;
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: PrestigeNoir.surfaceRaised,
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: PrestigeNoir.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: l10n.authSignIn,
              isActive: activeMode == AuthPrestigeMode.signIn,
              onTap: isLoading ? null : onSignIn,
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: l10n.authCreateAccount,
              isActive: activeMode == AuthPrestigeMode.signUp,
              onTap: isLoading ? null : onSignUp,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthPrestigePrimaryButton extends StatelessWidget {
  const AuthPrestigePrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return VButton(
      label: label,
      isLoading: isLoading,
      isFullWidth: true,
      size: ButtonSize.large,
      onPressed: isLoading ? null : onPressed,
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? PrestigeNoir.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: VFontSize.labelLg,
              fontWeight: VFontWeight.semiBold,
              color: isActive ? VColors.brand : PrestigeNoir.muted,
            ),
          ),
        ),
      ),
    );
  }
}
