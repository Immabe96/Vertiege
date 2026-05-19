import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/moderation_service.dart';
import '../theme/v_colors.dart';
import '../theme/design_system.dart';
import '../utils/date_format.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/core/loading_state.dart';
import '../widgets/core/empty_state.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  final String worldId;
  final String worldName;

  const AuditLogScreen({
    super.key,
    required this.worldId,
    required this.worldName,
  });

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await ModerationService.getAuditLog(widget.worldId);
      if (mounted)
        setState(() {
          _entries = entries;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = 'Failed to load audit log';
        });
    }
  }

  String _formatAction(String action) => switch (action) {
    'ban' => 'Banned a resident',
    'unban' => 'Unbanned a resident',
    'kick' => 'Kicked a resident',
    'mute' => 'Muted a resident',
    'unmute' => 'Unmuted a resident',
    'bulkDelete' => 'Deleted messages',
    'deleteMessage' => 'Deleted a message',
    'pinMessage' => 'Pinned a message',
    'unpinMessage' => 'Unpinned a message',
    'createRank' => 'Created a rank',
    'deleteRank' => 'Deleted a rank',
    'assignRank' => 'Assigned a rank',
    'removeRank' => 'Removed a rank',
    'editChannel' => 'Edited a channel',
    _ => action,
  };

  IconData _actionIcon(String action) => switch (action) {
    'ban' || 'kick' => Icons.gavel,
    'mute' || 'unmute' => Icons.volume_off,
    'bulkDelete' || 'deleteMessage' => Icons.delete,
    'pinMessage' || 'unpinMessage' => Icons.push_pin,
    'createRank' || 'deleteRank' => Icons.military_tech,
    'assignRank' || 'removeRank' => Icons.person_add,
    'editChannel' => Icons.edit,
    _ => Icons.history,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(title: Text('${widget.worldName} — Realm Audit')),
      body: _loading
          ? const GlassLoadingList(itemCount: 8)
          : _error != null
          ? AppErrorState(message: _error!, onRetry: _load)
          : _entries.isEmpty
          ? const AppEmptyState(
              title: 'No audit entries',
              description: 'Moderation actions will appear here.',
              icon: Icons.history,
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _load();
                await Future<void>.delayed(const Duration(milliseconds: 200));
              },
              child: ListView.builder(

                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final action = entry['action'] as String? ?? '';
                  final details = entry['details'] as Map<String, dynamic>?;
                  final createdAt = DateTime.tryParse(
                    entry['created_at'] ?? '',
                  );
                  final count = details?['count'] as int?;

                  return Padding(

                    ),
                    child: FCard(

                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (isDark
                                      ? VColors.surfaceContainerHighestDark
                                      : VColors.surfaceContainerHighest)
                                  .withValues(alpha: 0.5),

                              ),
                            ),
                            child: Icon(
                              _actionIcon(action),
                              size: IconSizes.sm,
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatAction(action),
                                  style: TextStyle(
                                    fontSize: FontSizes.bodyMd,
                                    fontWeight: FontWeights.semiBold,
                                    color: isDark
                                        ? VColors.onSurfaceDark
                                        : VColors.onSurface,
                                  ),
                                ),
                                if (entry['actor_id'] is String &&
                                    (entry['actor_id'] as String).isNotEmpty)
                                  Text(
                                    'by ${entry['actor_id']}',
                                    style: TextStyle(
                                      fontSize: FontSizes.labelSm,
                                      color: isDark
                                          ? VColors.onSurfaceVariantDark
                                          : VColors.onSurfaceVariant,
                                    ),
                                  ),
                                if (count != null)
                                  Text(
                                    '$count messages',
                                    style: TextStyle(
                                      fontSize: FontSizes.labelSm,
                                      color: isDark
                                          ? VColors.onSurfaceVariantDark
                                          : VColors.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              formatTimestamp(createdAt.millisecondsSinceEpoch),
                              style: TextStyle(
                                fontSize: FontSizes.labelSm,
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
