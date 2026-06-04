import 'package:flutter/material.dart';

import '../../services/feature_flags.dart';
import '../../services/whats_new_service.dart';
import '../../theme/v_tokens.dart';
import 'v_dialog.dart';

Future<void> showWhatsNewDialogIfNeeded(BuildContext context) async {
  if (!await WhatsNewService.shouldShow()) return;
  if (!context.mounted) return;

  final message = FeatureFlags.whatsNewMessage.trim();
  if (message.isEmpty) return;

  await showVDialog(
    context: context,
    title: "What's new",
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Got it'),
      ),
    ],
  );

  await WhatsNewService.markShown();
}
