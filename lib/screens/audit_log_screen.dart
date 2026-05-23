import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/moderation_service.dart';
import '../theme/v_colors.dart';
import '../forui/v_hub_page.dart';
import '../theme/v_tokens.dart';
import '../utils/date_format.dart';
import '../widgets/core/screen_loading.dart';
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
    return VHubPage(
      title: 'Realm Audit',
      showBack: true,
      body: _loading
          ? const ScreenLoading.list()
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
                padding: const EdgeInsets.all(VSpacing.md),
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
                    padding: EdgeInsets.only(
                      bottom: index < _entries.length - 1 ? VSpacing.sm : 0,
                    ),
                    child: _Card(
                      padding: const EdgeInsets.all(VSpacing.md),
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
                              borderRadius: BorderRadius.circular(
                                VRadius.md,
                              ),
                            ),
                            child: Icon(
                              _actionIcon(action),
                              size: VIconSize.sm,
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: VSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatAction(action),
                                  style: TextStyle(
                                    fontSize: VFontSize.bodyMd,
                                    fontWeight: VFontWeight.semiBold,
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
                                      fontSize: VFontSize.labelSm,
                                      color: isDark
                                          ? VColors.onSurfaceVariantDark
                                          : VColors.onSurfaceVariant,
                                    ),
                                  ),
                                if (count != null)
                                  Text(
                                    '$count messages',
                                    style: TextStyle(
                                      fontSize: VFontSize.labelSm,
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
                                fontSize: VFontSize.labelSm,
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

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(VSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}
