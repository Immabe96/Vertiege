import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/voice_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Shown while LiveKit is reconnecting with exponential backoff (Wave 19).
class CampfireReconnectBanner extends ConsumerWidget {
  const CampfireReconnectBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconnecting = ref.watch(
      voiceProvider.select((s) => s.isReconnecting),
    );
    if (!reconnecting) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? VColors.warningContainerDark
        : VColors.warningContainer;
    final foreground = isDark ? VColors.onSurfaceDark : VColors.onSurface;

    return Material(
      color: background.withValues(alpha: 0.95),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: VIconSize.sm,
                height: VIconSize.sm,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: VSpacing.sm),
              Text(
                'Reconnecting…',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.medium,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
