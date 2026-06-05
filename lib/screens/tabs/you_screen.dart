import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vertiege/ui/ui.dart';

import '../../legal/app_legal.dart';
import '../../services/feature_flags.dart';
import '../../theme/v_tokens.dart';
import 'identity_screen.dart';

/// Discord-style You tab: profile + settings links.
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VTabPage(
      title: 'You',
      body: Column(
        children: [
          const Expanded(child: IdentityScreen()),
          const Divider(height: 1),
          Flexible(
            flex: 0,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(VSpacing.md),
              children: [
                VSectionList(
                  title: 'Account',
                  children: [
                    VSectionTile(
                      icon: Icons.emoji_events_outlined,
                      label: 'Achievements',
                      onTap: () => context.push('/achievements'),
                    ),
                    VSectionTile(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Cosmetics Shop',
                      onTap: () => context.push('/shop'),
                    ),
                    VSectionTile(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.sm),
                VSectionList(
                  title: 'Help',
                  children: [
                    VSectionTile(
                      icon: Icons.feedback_outlined,
                      label: 'Beta feedback',
                      onTap: () => _openBetaFeedback(context),
                    ),
                    VSectionTile(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      onTap: () => AppLegal.showPrivacyPolicy(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBetaFeedback(BuildContext context) async {
    final url = Uri.tryParse(FeatureFlags.betaFeedbackUrl.trim());
    if (url == null || !await canLaunchUrl(url)) {
      if (!context.mounted) return;
      VFeedback.showMessage(context, 'Could not open feedback form.');
      return;
    }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
