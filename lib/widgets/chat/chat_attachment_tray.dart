import 'package:flutter/material.dart';
import 'package:vertiege/ui/ui.dart';

import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';

/// + attachment tray — image, achievement share (DCX-059).
void showChatAttachmentTray(
  BuildContext context, {
  VoidCallback? onAttachImage,
  VoidCallback? onShareAchievement,
}) {
  showVSheet(
    context,
    Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.md,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Add to message',
            style: TextStyle(
              fontSize: VFontSize.headlineSm,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimary,
            ),
          ),
          const SizedBox(height: VSpacing.md),
          if (onAttachImage != null)
            VTile(
              prefix: const Icon(Icons.image_outlined),
              title: const Text('Photo'),
              onPress: () {
                Navigator.pop(context);
                onAttachImage();
              },
            ),
          if (onShareAchievement != null)
            VTile(
              prefix: const Icon(Icons.emoji_events_outlined),
              title: const Text('Share achievement'),
              onPress: () {
                Navigator.pop(context);
                onShareAchievement();
              },
            ),
        ],
      ),
    ),
    maxSize: 0.35,
  );
}
