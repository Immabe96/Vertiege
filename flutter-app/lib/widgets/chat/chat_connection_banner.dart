import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/realtime_status_service.dart';
import '../../services/supabase.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/feedback/v_states.dart';

/// Thin banner shown on chat screens while Supabase Realtime is reconnecting.
class ChatConnectionBanner extends ConsumerWidget {
  const ChatConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isSupabaseConfigured()) {
      return const SizedBox.shrink();
    }

    final show = ref.watch(realtimeReconnectingProvider);
    if (!show) return const SizedBox.shrink();

    const background = VColors.warningContainerDark;
    const foreground = VColors.onSurfaceDark;

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
              VSpinner(
                size: VIconSize.sm,
                color: foreground.withValues(alpha: 0.9),
              ),
              const SizedBox(width: VSpacing.sm),
              const Text(
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
