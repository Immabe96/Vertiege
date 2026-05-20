import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';

enum SyncStatus { synced, syncing, pending, offline, error }

/// Small badge showing sync/connectivity status.
///
/// Used to communicate outbox mutation state and connectivity
/// to the user without blocking the UI.
class VSyncStatusBadge extends StatelessWidget {
  final SyncStatus status;
  final double size;

  const VSyncStatusBadge({
    super.key,
    this.status = SyncStatus.synced,
    this.size = 10,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      SyncStatus.synced => (Icons.check_circle, VColors.success),
      SyncStatus.syncing => (Icons.sync, VColors.primary),
      SyncStatus.pending => (Icons.schedule, VColors.warning),
      SyncStatus.offline => (Icons.cloud_off, VColors.onSurfaceVariant),
      SyncStatus.error => (Icons.error_outline, VColors.error),
    };

    return Icon(icon, size: size, color: color);
  }
}
