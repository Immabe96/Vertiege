import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Forui toasts — replaces [ScaffoldMessenger] snack bars under [FToaster].
abstract final class VFeedback {
  static void showMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    showFToast(
      context: context,
      title: Text(message),
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
  }) {
    showFToast(
      context: context,
      variant: .destructive,
      title: Text(message),
      duration: duration,
    );
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
