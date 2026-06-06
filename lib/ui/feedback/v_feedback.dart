import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../config/achievements.dart' as ach_config;
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/achievements/achievement_icon.dart';

/// Forui toasts — replaces [ScaffoldMessenger] snack bars under [FToaster].
abstract final class VFeedback {
  static void showMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (_tryFToast(context, message, duration: duration)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
  }) {
    if (_tryFToast(
      context,
      message,
      duration: duration,
      destructive: true,
    )) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: duration),
    );
  }

  static bool _tryFToast(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    bool destructive = false,
  }) {
    try {
      if (destructive) {
        showFToast(
          context: context,
          variant: .destructive,
          title: Text(message),
          duration: duration,
        );
      } else {
        showFToast(
          context: context,
          title: Text(message),
          duration: duration,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Bottom toast with achievement art — chat-native unlock moment (DCX-093).
  static void showAchievementUnlock(
    BuildContext context, {
    required String achievementId,
    String? subtitle,
    VoidCallback? onShareToNexus,
  }) {
    final achievement = ach_config.achievementForId(achievementId);
    if (achievement == null) {
      showMessage(context, 'Achievement verified');
      return;
    }
    final meta = metaForCategory(achievement.category);
    Haptics.success();
    try {
      showFToast(
        context: context,
        duration: const Duration(seconds: 6),
        icon: AchievementBadgeAvatar(
          achievement: achievement,
          accentColor: meta.color,
          size: 36,
          showEarnedBadge: true,
        ),
        title: Text(
          achievement.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: VFontWeight.bold),
        ),
        description: Text(
          subtitle ?? 'Achievement verified',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: VCommuneColors.textMuted),
        ),
        suffixBuilder: onShareToNexus == null
            ? null
            : (ctx, entry) => FButton(
                size: .sm,
                variant: .ghost,
                onPress: () {
                  entry.dismiss();
                  onShareToNexus();
                },
                child: const Text('Nexus'),
              ),
      );
    } catch (_) {
      showMessage(context, '${achievement.title} verified');
    }
  }

  static void showWithAction(
    BuildContext context, {
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    showFToast(
      context: context,
      title: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
      duration: duration,
      suffixBuilder: (ctx, entry) => FButton(
        size: .sm,
        variant: .ghost,
        onPress: () {
          entry.dismiss();
          onAction();
        },
        child: Text(actionLabel),
      ),
    );
  }
}
