import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../services/moderation_service.dart';
import '../theme/v_colors.dart';
import 'package:vertiege/ui/ui.dart';
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

enum _AuditFilter { all, treasury, rank, job, poll }

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  List<Map<String, dynamic>> _entries = [];
  Map<String, String> _actorNames = {};
  bool _loading = true;
  String? _error;
  _AuditFilter _filter = _AuditFilter.all;

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
      final names = await ModerationService.resolveActorNames(
        entries.map((e) => e['actor_id'] as String? ?? ''),
      );
      if (mounted) {
        setState(() {
          _entries = entries;
          _actorNames = names;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load audit log';
        });
      }
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
    'governance_proposal_approved' => 'Council approved a request',
    'governance_proposal_rejected' => 'Council rejected a request',
    'governance_treasury_proposed' => 'Treasury withdrawal proposed',
    'governance_treasury_executed' => 'Treasury withdrawal executed',
    'poll_moderated' => 'Council moderated a poll',
    'governance_job_executed' => 'Published a role post',
    'governance_rank_change_executed' => 'Changed a member rank',
    'governance_treasury_withdrawal' => 'Withdrew from treasury',
    _ => action.replaceAll('_', ' '),
  };

  String? _governanceDetail(Map<String, dynamic>? details) {
    if (details == null) return null;
    final type = details['type'] as String?;
    if (type != null && type.isNotEmpty) {
      return switch (type) {
        'treasury_withdrawal' => 'Treasury withdrawal',
        'job_publish' => 'Role post',
        'rank_change' => 'Rank change',
        _ => type.replaceAll('_', ' '),
      };
    }
    final title = details['title'] as String?;
    if (title != null && title.isNotEmpty) return title;
    final amount = details['amount'];
    if (amount != null) return '$amount coins';
    final action = details['action'] as String?;
    if (action != null) {
      return 'Rank ${action == 'assign' ? 'assigned' : 'removed'}';
    }
    return null;
  }

  String _actorLabel(String? actorId) {
    if (actorId == null || actorId.isEmpty) return '';
    return _actorNames[actorId] ?? 'Resident';
  }

  IconData _actionIcon(String action) => switch (action) {
    'ban' || 'kick' => Icons.gavel,
    'mute' || 'unmute' => Icons.volume_off,
    'bulkDelete' || 'deleteMessage' => Icons.delete,
    'pinMessage' || 'unpinMessage' => Icons.push_pin,
    'createRank' || 'deleteRank' => Icons.military_tech,
    'assignRank' || 'removeRank' => Icons.person_add,
    'editChannel' => Icons.edit,
    'governance_proposal_approved' ||
    'governance_proposal_rejected' ||
    'governance_job_executed' ||
    'governance_rank_change_executed' ||
    'governance_treasury_withdrawal' ||
    'governance_treasury_proposed' ||
    'governance_treasury_executed' => Icons.gavel,
    'poll_moderated' => Icons.poll,
    _ => Icons.history,
  };

  bool _matchesFilter(Map<String, dynamic> entry) {
    if (_filter == _AuditFilter.all) return true;
    final action = entry['action'] as String? ?? '';
    final details = entry['details'] as Map<String, dynamic>?;
    final type = details?['type'] as String?;
    return switch (_filter) {
      _AuditFilter.treasury =>
        action.contains('treasury') || type == 'treasury_withdrawal',
      _AuditFilter.rank => action.contains('rank') || type == 'rank_change',
      _AuditFilter.job => action.contains('job') || type == 'job_publish',
      _AuditFilter.poll => action == 'poll_moderated',
      _AuditFilter.all => true,
    };
  }

  List<Map<String, dynamic>> get _filteredEntries =>
      _entries.where(_matchesFilter).toList();

  Future<void> _exportCsv() async {
    final rows = _filteredEntries;
    if (rows.isEmpty) return;
    final buffer = StringBuffer('timestamp,action,actor,detail\n');
    for (final entry in rows) {
      final createdAt = DateTime.tryParse(
        entry['created_at']?.toString() ?? '',
      );
      final action = entry['action'] as String? ?? '';
      final actor = _actorLabel(entry['actor_id'] as String?);
      final detail =
          _governanceDetail(entry['details'] as Map<String, dynamic>?) ?? '';
      buffer.writeln(
        '"${createdAt?.toIso8601String() ?? ''}","$action","$actor","$detail"',
      );
    }
    await Share.share(
      buffer.toString(),
      subject: '${widget.worldName} audit export',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return VHubPage(
      title: 'Realm Audit',
      showBack: true,
      headerActions: [
        if (_filteredEntries.isNotEmpty)
          IconButton(
            tooltip: 'Export CSV',
            icon: const Icon(Icons.ios_share),
            onPressed: _exportCsv,
          ),
      ],
      body: _loading
          ? const ScreenLoading.list()
          : _error != null
          ? AppErrorState(message: _error!, onRetry: _load)
          : _entries.isEmpty
          ? const AppEmptyState(
              title: 'No audit entries',
              description: 'Moderation and council decisions will appear here.',
              icon: Icons.history,
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _load();
                await Future<void>.delayed(const Duration(milliseconds: 200));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(VSpacing.md),
                itemCount: _filteredEntries.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: VSpacing.md),
                      child: Wrap(
                        spacing: VSpacing.xs,
                        runSpacing: VSpacing.xs,
                        children: _AuditFilter.values.map((f) {
                          final selected = _filter == f;
                          return FilterChip(
                            label: Text(switch (f) {
                              _AuditFilter.all => 'All',
                              _AuditFilter.treasury => 'Treasury',
                              _AuditFilter.rank => 'Rank',
                              _AuditFilter.job => 'Jobs',
                              _AuditFilter.poll => 'Polls',
                            }),
                            selected: selected,
                            onSelected: (_) => setState(() => _filter = f),
                          );
                        }).toList(),
                      ),
                    );
                  }
                  final entry = _filteredEntries[index - 1];
                  final action = entry['action'] as String? ?? '';
                  final details = entry['details'] as Map<String, dynamic>?;
                  final createdAt = DateTime.tryParse(
                    entry['created_at'] ?? '',
                  );
                  final count = details?['count'] as int?;
                  final govDetail = _governanceDetail(details);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _filteredEntries.length ? VSpacing.sm : 0,
                    ),
                    child: _Card(
                      padding: const EdgeInsets.all(VSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  (isDark
                                          ? VColors.surfaceContainerHighestDark
                                          : VColors.surfaceContainerHighest)
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(VRadius.md),
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
                                if (govDetail != null)
                                  Text(
                                    govDetail,
                                    style: TextStyle(
                                      fontSize: VFontSize.labelSm,
                                      color: isDark
                                          ? VColors.onSurfaceVariantDark
                                          : VColors.onSurfaceVariant,
                                    ),
                                  ),
                                if (entry['actor_id'] is String &&
                                    (entry['actor_id'] as String).isNotEmpty)
                                  Text(
                                    'by ${_actorLabel(entry['actor_id'] as String)}',
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
    return Container(
      padding: padding ?? const EdgeInsets.all(VSpacing.lg),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerDark,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(color: VColors.outlineVariantDark),
      ),
      child: child,
    );
  }
}
