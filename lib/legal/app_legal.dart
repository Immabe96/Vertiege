import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/build_info.dart';
import '../services/feature_flags.dart';
import '../theme/v_tokens.dart';
import '../ui/buttons/v_button.dart';
import '../widgets/core/v_dialog.dart';

/// Shared privacy, terms, and license surfaces.
class AppLegal {
  AppLegal._();

  /// Hosted URLs from Remote Config when set; otherwise in-app copy only.
  static Uri? get privacyPolicyUri {
    final raw = FeatureFlags.privacyPolicyUrl.trim();
    if (raw.isEmpty) return null;
    return Uri.tryParse(raw);
  }

  static Uri? get termsOfServiceUri {
    final raw = FeatureFlags.termsOfServiceUrl.trim();
    if (raw.isEmpty) return null;
    return Uri.tryParse(raw);
  }

  static Future<void> _openUri(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Settings / Help hub — privacy, terms, licenses.
  static void showLegalHub(BuildContext context) {
    showVDialog(
      context: context,
      title: 'Legal',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VButton(
            label: 'Privacy Policy',
            variant: ButtonVariant.text,
            onPressed: () {
              Navigator.pop(context);
              showPrivacyPolicy(context);
            },
          ),
          VButton(
            label: 'Terms of Service',
            variant: ButtonVariant.text,
            onPressed: () {
              Navigator.pop(context);
              showTermsOfService(context);
            },
          ),
          VButton(
            label: 'Open-source licenses',
            variant: ButtonVariant.text,
            onPressed: () {
              Navigator.pop(context);
              showOpenSourceLicenses(context);
            },
          ),
        ],
      ),
      actions: [
        vDialogActionsRow([
          VButton(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.text,
          ),
        ]),
      ],
    );
  }

  static void showPrivacyPolicy(BuildContext context) {
    final theme = Theme.of(context);
    final hosted = privacyPolicyUri;
    showVDialog(
      context: context,
      title: 'Privacy Policy',
      scrollContent: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Last updated: July 2026', style: theme.textTheme.bodySmall),
          const SizedBox(height: VSpacing.md),
          Text(
            'Information We Collect',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          const Text(
            'We collect information you provide directly, such as your profile data, '
            'posts, chats, achievement proofs, and device tokens for notifications. '
            'If you use Campfire voice, we process audio for the live session only.',
          ),
          const SizedBox(height: VSpacing.md),
          Text(
            'How We Use Your Data',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          const Text(
            'Your data is used to provide and improve Vertiege services, personalize '
            'your experience, verify achievements, and communicate important updates. '
            'We never sell your personal data.',
          ),
          const SizedBox(height: VSpacing.md),
          Text(
            'Data Storage & Security',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          const Text(
            'Data is stored securely using Supabase infrastructure with encryption '
            'at rest and in transit. You may delete your account from Settings; '
            'deletion removes your profile and associated personal data from our systems.',
          ),
          const SizedBox(height: VSpacing.md),
          Text(
            'Contact',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          const Text('privacy@vertiege.app'),
        ],
      ),
      actions: [
        vDialogActionsRow([
          if (hosted != null)
            VButton(
              label: 'View online',
              onPressed: () => _openUri(hosted),
              variant: ButtonVariant.text,
            ),
          VButton(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.text,
          ),
        ]),
      ],
    );
  }

  static void showTermsOfService(BuildContext context) {
    final theme = Theme.of(context);
    final hosted = termsOfServiceUri;
    showVDialog(
      context: context,
      title: 'Terms of Service',
      scrollContent: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Last updated: July 2026', style: theme.textTheme.bodySmall),
          const SizedBox(height: VSpacing.md),
          Text(
            '1. Acceptance of Terms',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          const Text(
            'By using Vertiege, you agree to these terms. If you do not agree, '
            'do not use the service.',
          ),
          const SizedBox(height: VSpacing.md),
          Text(
            '2. User Conduct',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          const Text(
            'Harassment, hate speech, spam, and illegal content are prohibited. '
            'World sovereigns may enforce additional rules. You may report content '
            'from posts and messages; we review reports and may suspend accounts '
            'that violate these terms.',
          ),
          const SizedBox(height: VSpacing.md),
          Text(
            '3. Account deletion',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          const Text(
            'You may delete your account at any time from Settings. Deletion is '
            'permanent and removes your profile and personal data.',
          ),
        ],
      ),
      actions: [
        vDialogActionsRow([
          if (hosted != null)
            VButton(
              label: 'View online',
              onPressed: () => _openUri(hosted),
              variant: ButtonVariant.text,
            ),
          VButton(
            label: 'Close',
            onPressed: () => Navigator.pop(context),
            variant: ButtonVariant.text,
          ),
        ]),
      ],
    );
  }

  static void showOpenSourceLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Vertiege',
      applicationVersion: kAppVersionLabel,
      applicationLegalese: 'Copyright 2026 Vertiege',
    );
  }
}
