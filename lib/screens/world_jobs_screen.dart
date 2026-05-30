import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../config/tiers.dart';
import '../forui/v_hub_page.dart';
import '../models/resident.dart';
import '../models/world_job.dart';
import '../models/world_job_application.dart';
import '../models/world.dart';
import '../services/world_job_service.dart';
import '../state/resident_provider.dart';
import '../state/world_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/core/v_dialog.dart';
import '../widgets/core/v_feedback.dart';
import '../widgets/core/new_user_context_hint.dart';
import '../ui/icons/v_icons.dart';

class WorldJobsScreen extends ConsumerStatefulWidget {
  final String worldId;
  final bool canManage;

  const WorldJobsScreen({
    super.key,
    required this.worldId,
    this.canManage = false,
  });

  @override
  ConsumerState<WorldJobsScreen> createState() => _WorldJobsScreenState();
}

class _WorldJobsScreenState extends ConsumerState<WorldJobsScreen> {
  List<WorldJob> _jobs = [];
  Map<String, WorldJobApplicationStatus> _myApplicationByJob = {};
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
      final jobs = await WorldJobService.fetchJobs(
        widget.worldId,
        openOnly: false,
      );
      final statuses = await WorldJobService.fetchMyApplicationStatuses(
        jobs.map((j) => j.id).toList(),
      );
      if (!mounted) return;
      setState(() {
        _jobs = jobs;
        _myApplicationByJob = statuses;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load roles.';
      });
    }
  }

  Future<void> _showCreateDialog() async {
    final title = TextEditingController();
    final desc = TextEditingController();
    final role = TextEditingController(text: 'Contributor');
    var minStanding = 3;
    var minTier = 2;

    final ok = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog.raw(
        builder: (context, dialogStyle) => StatefulBuilder(
          builder: (ctx, setLocal) => Padding(
            padding: const EdgeInsets.all(VSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Post a role',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: VFontWeight.bold,
                      ),
                ),
                const SizedBox(height: VSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: title,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: VSpacing.sm),
                        TextField(
                          controller: desc,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: VSpacing.sm),
                        TextField(
                          controller: role,
                          decoration: const InputDecoration(
                            labelText: 'Role label',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: VSpacing.sm),
                        DropdownButtonFormField<int>(
                          value: minStanding,
                          decoration: const InputDecoration(
                            labelText: 'Min standing',
                            border: OutlineInputBorder(),
                          ),
                          items: standingLevels
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.level,
                                  child: Text(s.title),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setLocal(() => minStanding = v ?? 3),
                        ),
                        DropdownButtonFormField<int>(
                          value: minTier,
                          decoration: const InputDecoration(
                            labelText: 'Min global tier',
                            border: OutlineInputBorder(),
                          ),
                          items: tierNames.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setLocal(() => minTier = v ?? 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: VSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: VSpacing.sm),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (ok != true) return;
    if (title.text.trim().isEmpty || desc.text.trim().isEmpty) return;

    try {
      await WorldJobService.createJob(
        worldId: widget.worldId,
        title: title.text.trim(),
        description: desc.text.trim(),
        roleLabel: role.text.trim(),
        minStandingLevel: minStanding,
        minTier: minTier,
      );
      if (mounted) {
        VFeedback.showMessage(context, 'Role posted');
        _load();
      }
    } catch (e) {
      if (mounted) {
        VFeedback.showError(context, 'Could not post role: $e');
      }
    }
  }

  Future<void> _showApplyDialog(WorldJob job) async {
    final message = TextEditingController();

    final ok = await showVDialog<bool>(
      context: context,
      title: 'Apply for ${job.title}',
      content: TextField(
        controller: message,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Why you\'re a fit (optional)',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
      ),
      actions: [
        vDialogActionsRow([
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit application'),
          ),
        ]),
      ],
    );

    if (ok != true) return;

    try {
      await WorldJobService.applyToJob(
        jobId: job.id,
        message: message.text.trim(),
      );
      if (mounted) {
        VFeedback.showMessage(context, 'Application submitted');
        _load();
      }
    } catch (e) {
      if (mounted) {
        VFeedback.showError(context, '$e');
      }
    }
  }

  Future<void> _showApplicants(WorldJob job) async {
    final apps = await WorldJobService.fetchApplications(job.id);
    if (!mounted) return;

    final pending = apps.where((a) => a.isPending).toList();
    if (pending.isEmpty) {
      VFeedback.showMessage(context, 'No pending applications');
      return;
    }

    await showVDialog<void>(
      context: context,
      title: 'Applications',
      scrollContent: true,
      maxContentHeight: 400,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final app in pending) ...[
            Text(
              app.applicantId,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
            ),
            if (app.message.isNotEmpty) ...[
              const SizedBox(height: VSpacing.xs),
              Text(app.message),
            ],
            const SizedBox(height: VSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final accepted =
                      await WorldJobService.acceptApplication(app.id);
                  if (!context.mounted) return;
                  if (accepted) {
                    Navigator.pop(context);
                    VFeedback.showMessage(
                      context,
                      'Application accepted — role marked filled',
                    );
                    _load();
                  } else {
                    VFeedback.showError(
                      context,
                      'Could not accept application',
                    );
                  }
                },
                child: const Text('Accept'),
              ),
            ),
            const Divider(height: VSpacing.lg),
          ],
        ],
      ),
      actions: [
        vDialogActionsRow([
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return VHubPage(
      title: 'World roles',
      showBack: true,
      headerActions: widget.canManage
          ? [
              FHeaderAction(
                icon: const Icon(VIcons.plus),
                onPress: _showCreateDialog,
              ),
            ]
          : const [],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NewUserContextHint(
            message:
                'Roles respect world standing and tier. Apply when you qualify; council can review applicants.',
            icon: Icons.work_outline,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ScreenLoading.list();
    if (_error != null) {
      return AppEmptyState(
        title: 'Could not load',
        description: _error!,
        icon: Icons.work_outline,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }
    if (_jobs.isEmpty) {
      return AppEmptyState(
        title: 'No open roles',
        description: widget.canManage
            ? 'Post responsibilities for contributors, moderators, or event leads.'
            : 'Council will post roles when they need help running the world.',
        icon: Icons.work_outline,
        actionLabel: widget.canManage ? 'Post role' : null,
        onAction: widget.canManage ? _showCreateDialog : null,
      );
    }

    final theme = Theme.of(context);
    final resident = ref.watch(residentProvider).resident;
    final world = ref.watch(worldProvider).worlds[widget.worldId];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(VSpacing.md),
        itemCount: _jobs.length,
        separatorBuilder: (_, _) => const SizedBox(height: VSpacing.sm),
        itemBuilder: (_, i) {
          final job = _jobs[i];
          final eligible = _isEligible(resident, world, job);
          final myStatus = _myApplicationByJob[job.id];
          final hasApplied = myStatus != null;
          return FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          job.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: VFontWeight.bold,
                          ),
                        ),
                      ),
                      _StatusChip(status: job.status),
                    ],
                  ),
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    job.roleLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: VColors.primary,
                    ),
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Text(job.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: VSpacing.sm),
                  Text(
                    'Requires ${standingLevels[job.minStandingLevel - 1].title} · '
                    '${tierNames[job.minTier] ?? 'Tier ${job.minTier}'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (job.isOpen && !eligible)
                    Padding(
                      padding: const EdgeInsets.only(top: VSpacing.sm),
                      child: Text(
                        'Build standing and tier to qualify.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: VColors.warning,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (job.isOpen && hasApplied)
                    Padding(
                      padding: const EdgeInsets.only(top: VSpacing.sm),
                      child: Text(
                        myStatus == WorldJobApplicationStatus.accepted
                            ? 'You were accepted for this role.'
                            : 'Application pending review.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: VColors.primary,
                          fontWeight: VFontWeight.semiBold,
                        ),
                      ),
                    ),
                  if (job.isOpen && eligible && !hasApplied) ...[
                    const SizedBox(height: VSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton(
                        onPressed: () => _showApplyDialog(job),
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                  if (widget.canManage && job.isOpen) ...[
                    const SizedBox(height: VSpacing.sm),
                    Wrap(
                      spacing: VSpacing.sm,
                      children: [
                        TextButton(
                          onPressed: () => _showApplicants(job),
                          child: const Text('Applicants'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await WorldJobService.updateStatus(
                              job.id,
                              WorldJobStatus.filled,
                            );
                            _load();
                          },
                          child: const Text('Mark filled'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await WorldJobService.updateStatus(
                              job.id,
                              WorldJobStatus.closed,
                            );
                            _load();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isEligible(Resident? resident, World? world, WorldJob job) {
    if (resident == null || world == null) return false;
    if (resident.tier.value < job.minTier) return false;
    final rep = resident.worldStandings[widget.worldId]?.rep ?? 0;
    return getStanding(rep).level >= job.minStandingLevel;
  }
}

class _StatusChip extends StatelessWidget {
  final WorldJobStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      WorldJobStatus.open => ('Open', VColors.success),
      WorldJobStatus.filled => ('Filled', VColors.primary),
      WorldJobStatus.closed => ('Closed', VColors.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: VFontSize.labelSm,
          color: color,
          fontWeight: VFontWeight.bold,
        ),
      ),
    );
  }
}
