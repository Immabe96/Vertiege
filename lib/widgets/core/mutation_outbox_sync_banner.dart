import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/mutation_outbox_service.dart';
import '../../state/post_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/feedback/v_states.dart';

/// Quiet strip when the mutation outbox has pending or failed items.
class MutationOutboxSyncBanner extends ConsumerStatefulWidget {
  const MutationOutboxSyncBanner({super.key});

  @override
  ConsumerState<MutationOutboxSyncBanner> createState() =>
      _MutationOutboxSyncBannerState();
}

class _MutationOutboxSyncBannerState
    extends ConsumerState<MutationOutboxSyncBanner> {
  Timer? _timer;
  int _pending = 0;
  int _failed = 0;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final pending = await MutationOutboxService.pendingCount();
    final failed = (await MutationOutboxService.getFailed()).length;
    if (!mounted) return;
    if (pending == _pending && failed == _failed) return;
    setState(() {
      _pending = pending;
      _failed = failed;
    });
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      // loadPosts replays the post outbox before refreshing the feed.
      await ref.read(postProvider.notifier).loadPosts();
    } finally {
      if (mounted) {
        setState(() => _retrying = false);
        await _refresh();
      }
    }
  }

  Future<void> _discardFailed() async {
    await MutationOutboxService.discardFailed();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_pending <= 0 && _failed <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final hasFailed = _failed > 0;
    final label = hasFailed && _pending <= 0
        ? (_failed == 1
              ? '1 change failed to sync'
              : '$_failed changes failed to sync')
        : (_pending == 1
              ? '1 change waiting to sync'
              : '$_pending changes waiting to sync');

    return Material(
      color: hasFailed
          ? VColors.error.withValues(alpha: 0.10)
          : VColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.sm,
          vertical: VSpacing.xs,
        ),
        child: Row(
          children: [
            if (_retrying)
              const VSpinner(size: 14)
            else
              Icon(
                hasFailed ? Icons.cloud_off_outlined : Icons.cloud_sync_outlined,
                size: VIconSize.sm,
                color: hasFailed
                    ? VColors.error
                    : theme.colorScheme.primary,
              ),
            const SizedBox(width: VSpacing.sm),
            Expanded(
              child: Text(label, style: theme.textTheme.bodySmall),
            ),
            TextButton(
              onPressed: _retrying ? null : _retry,
              child: const Text('Retry'),
            ),
            if (hasFailed)
              TextButton(
                onPressed: _retrying ? null : _discardFailed,
                child: const Text('Dismiss'),
              ),
          ],
        ),
      ),
    );
  }
}
