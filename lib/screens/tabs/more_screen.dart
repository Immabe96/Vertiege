import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../forui/v_hub_page.dart';
import '../../legal/app_legal.dart';
import '../../services/feature_flags.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/v_feedback.dart';
import '../../widgets/v_section_list.dart';

/// Secondary navigation hub — accessible via the More tab.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(residentProvider).resident?.tier.value ?? 1;
    return VHubPage(
      title: 'More',
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.md),
        children: [
          VSectionList(
            title: 'Account',
            children: [
              VSectionTile(
                icon: Icons.shopping_bag,
                label: 'Cosmetics Shop',
                onTap: () => context.push('/shop'),
              ),
              VSectionTile(
                icon: Icons.workspace_premium,
                label: 'Subscription',
                detail: tier < 2 ? 'Unlocks at High Roller' : null,
                onTap: () => context.push('/subscription'),
              ),
              VSectionTile(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () => context.push('/settings'),
              ),
              VSectionTile(
                icon: Icons.notifications,
                label: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          VSectionList(
            title: 'Help & legal',
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
              VSectionTile(
                icon: Icons.gavel_outlined,
                label: 'Terms of Service',
                onTap: () => AppLegal.showTermsOfService(context),
              ),
              VSectionTile(
                icon: Icons.article_outlined,
                label: 'Open Source Licenses',
                onTap: () => AppLegal.showOpenSourceLicenses(context),
              ),
            ],
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
