import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/realtime_status_service.dart';
import '../../services/supabase.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

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
