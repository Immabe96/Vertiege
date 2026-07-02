import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../services/device_permission_service.dart';
import '../../services/notification_onboarding_prefs.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';

/// Shared design for post-signup notification opt-in (iOS + Android).
Future<void> showNotificationPermissionSheet(BuildContext context) async {
  if (!context.mounted) return;

  await showFDialog<void>(
    context: context,
    builder: (ctx, style, animation) => FDialog.raw(
      builder: (context, dialogStyle) => Padding(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Stay in the loop',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            const Text(
              'Get alerts for likes, comments, world invites, and DMs. '
              'You can change this anytime in Settings.',
            ),
            const SizedBox(height: VSpacing.lg),
            VButton(
              label: 'Enable notifications',
              isFullWidth: true,
              onPressed: () async {
                await DevicePermissionService.requestNotifications();
                await NotificationOnboardingPrefs.markCompleted();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: VSpacing.sm),
            VButton(
              label: 'Not now',
              variant: ButtonVariant.text,
              isFullWidth: true,
              onPressed: () async {
                await NotificationOnboardingPrefs.markCompleted();
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    ),
  );
}
