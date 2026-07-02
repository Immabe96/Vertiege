import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/mutation_outbox_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/feedback/v_states.dart';

/// Quiet strip when the mutation outbox has pending items (Wave 21).
class MutationOutboxSyncBanner extends StatefulWidget {
  const MutationOutboxSyncBanner({super.key});

  @override
  State<MutationOutboxSyncBanner> createState() =>
      _MutationOutboxSyncBannerState();
}

class _MutationOutboxSyncBannerState extends State<MutationOutboxSyncBanner> {
  Timer? _timer;
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final count = await MutationOutboxService.pendingCount();
    if (!mounted || count == _pending) return;
    setState(() => _pending = count);
  }

  @override
  Widget build(BuildContext context) {
    if (_pending <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Material(
      color: VColors.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: VSpacing.sm,
          vertical: VSpacing.xs,
        ),
        child: Row(
          children: [
            const VSpinner(size: 14),
            const SizedBox(width: VSpacing.sm),
            Expanded(
              child: Text(
                _pending == 1
                    ? 'Syncing 1 change when you\'re back online'
                    : 'Syncing $_pending changes when you\'re back online',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
