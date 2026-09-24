import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/post_provider.dart';
import '../../ui/feedback/v_feedback.dart';

/// Surfaces [PostState.lastError] app-wide (comments, votes, delete, etc.).
/// Compose still uses lastError for hard-fail detection; this owns the toast.
class PostActionErrorListener extends ConsumerWidget {
  final Widget child;

  const PostActionErrorListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<String?>(postProvider.select((s) => s.lastError), (prev, next) {
      if (next == null || next == prev) return;
      if (next == 'Post queued for sync') {
        VFeedback.showMessage(context, next);
      } else {
        VFeedback.showError(context, next);
      }
      ref.read(postProvider.notifier).clearError();
    });
    return child;
  }
}
