import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:vertiege/l10n/app_localizations.dart';
import 'package:vertiege/ui/ui.dart';
import '../../config/progression_access.dart';
import '../../services/admin_access_service.dart';
import '../../state/achievement_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import 'settings_prestige_section.dart';

/// Account-related settings tiles (shop, auth, sign out, delete).
class SettingsAccountSection extends ConsumerWidget {
  const SettingsAccountSection({
    super.key,
    required this.verifierQueueCount,
    required this.onChangeEmail,
    required this.onChangePassword,
    required this.onDeleteAccount,
    required this.onSignOut,
  });

  final int verifierQueueCount;
  final VoidCallback onChangeEmail;
  final VoidCallback onChangePassword;
  final VoidCallback onDeleteAccount;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return SettingsPrestigeSection(
      title: 'Account',
      children: [
        Builder(
          builder: (context) {
            final coins =
                ref.watch(residentProvider).resident?.sovereignCoins ?? 0;
            final unlocked = ProgressionAccess.canAccessShop(
              ref.watch(achievementProvider).userAchievements,
            );
            return VSectionTile(
              icon: unlocked ? Icons.monetization_on : Icons.lock_outline,
              label: 'Shop',
              detail: unlocked
                  ? '$coins coins'
                  : 'Unlock after first verified achievement',
              iconColor: unlocked ? VColors.tertiary : null,
              onTap: () => context.push('/shop'),
            );
          },
        ),
        VSectionTile(
          icon: Icons.workspace_premium,
          label: 'Subscription',
          onTap: () => context.push('/subscription'),
        ),
        if (AdminAccessService.isCurrentSessionVerifier())
          VSectionTile(
            icon: Icons.verified_user_outlined,
            label: 'Staff review',
            detail: verifierQueueCount > 0
                ? '$verifierQueueCount in verifier queue'
                : 'Achievement & profession review',
            onTap: () => context.push('/verifier/review'),
          ),
        VSectionTile(
          icon: Icons.email_outlined,
          label: 'Change Email',
          onTap: onChangeEmail,
        ),
        VSectionTile(
          icon: Icons.lock_outline,
          label: 'Change Password',
          onTap: onChangePassword,
        ),
        VSectionTile(
          icon: Icons.security,
          label: 'Twin Seal (2FA)',
          iconColor: VColors.tertiary,
          onTap: () => context.push('/twin-seal'),
        ),
        VSectionTile(
          icon: Icons.monetization_on_outlined,
          label: 'Coin history',
          onTap: () => context.push('/coin-history'),
        ),
        VSectionTile(
          icon: Icons.delete_outline,
          label: l10n.deleteAccount,
          iconColor: VColors.error,
          titleColor: VColors.error,
          onTap: onDeleteAccount,
        ),
        VSectionTile(
          icon: Icons.logout,
          label: l10n.signOut,
          iconColor: VColors.error,
          titleColor: VColors.error,
          onTap: onSignOut,
        ),
      ],
    );
  }
}
