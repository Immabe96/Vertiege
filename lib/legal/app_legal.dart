import 'package:flutter/material.dart';

import '../config/build_info.dart';
import '../theme/v_tokens.dart';
import '../ui/buttons/v_button.dart';
import '../widgets/core/v_dialog.dart';

/// Shared privacy, terms, and license surfaces (Wave 15 — More + Settings).
class AppLegal {
  AppLegal._();

  static void showPrivacyPolicy(BuildContext context) {
    final theme = Theme.of(context);
    showVDialog(
      context: context,
      title: 'Privacy Policy',
      scrollContent: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Last updated: May 2025', style: theme.textTheme.bodySmall),
          const SizedBox(height: VSpacing.md),
          Text(
            'Information We Collect',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          const Text(
            'We collect information you provide directly, such as your profile data, posts, and interactions.',
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
            'Your data is used to provide and improve Vertiege services, personalize your experience, '
            'and communicate important updates. We never sell your personal data.',
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
            'Data is stored securely using Supabase infrastructure with encryption at rest and in transit.',
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
    showVDialog(
      context: context,
      title: 'Terms of Service',
      scrollContent: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Last updated: May 2025', style: theme.textTheme.bodySmall),
          const SizedBox(height: VSpacing.md),
          Text(
            '1. Acceptance of Terms',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          const Text(
            'By using Vertiege, you agree to these terms. If you do not agree, do not use the service.',
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
            'World sovereigns may enforce additional rules.',
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

  static void showOpenSourceLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Vertiege',
      applicationVersion: kAppVersionLabel,
      applicationLegalese: 'Copyright 2025 Vertiege',
    );
  }
}
