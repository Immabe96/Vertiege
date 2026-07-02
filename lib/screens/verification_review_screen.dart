import 'package:flutter/material.dart';
import 'package:vertiege/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../config/achievement_reject_reasons.dart';
import '../config/achievements.dart';
import '../config/identity_verification.dart';
import '../services/gamification_service.dart';
import '../services/verification_service.dart';
import '../services/achievement_review_service.dart';
import '../widgets/achievements/achievement_verifier_review_card.dart';
import '../state/post_provider.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../ui/buttons/v_button.dart';
import '../ui/overlays/v_dialog.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';

class VerificationReviewScreen extends ConsumerStatefulWidget {
  const VerificationReviewScreen({super.key});

  @override
  ConsumerState<VerificationReviewScreen> createState() =>
      _VerificationReviewScreenState();
}

class _VerificationReviewScreenState
    extends ConsumerState<VerificationReviewScreen> {
  List<VerificationSubmission> _submissions = [];
  List<PendingAchievementSubmission> _achievementSubmissions = [];
  bool _loading = true;
  bool _achievementsLoading = true;
  bool _compactVerifierMode = false;
  VerifierQueueMetrics? _queueMetrics;

  @override
  void initState() {
    super.initState();
    _load();
    _loadAchievements();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    final metrics = await AchievementReviewService.getQueueMetrics();
    if (mounted) setState(() => _queueMetrics = metrics);
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final pending = await VerificationService.getPending();
    if (mounted) {
      setState(() {
        _submissions = pending;
        _loading = false;
      });
    }
  }

  Future<void> _loadAchievements() async {
    setState(() => _achievementsLoading = true);
    final pending = await AchievementReviewService.getPending();
    if (mounted) {
      setState(() {
        _achievementSubmissions = pending;
        _achievementsLoading = false;
      });
    }
  }

  Future<void> _approve(VerificationSubmission s) async {
    await VerificationService.approve(s.id);
    if (IdentityVerification.isIdentityProfession(s.profession)) {
      _load();
      return;
    }
    final achievementId = achievementIdForVerifiedProfession(s.profession);
    if (achievementId != null) {
      try {
        await GamificationService.grantVerifiedAchievement(
          userId: s.residentId,
          achievementId: achievementId,
          reviewerNotes: 'Profession verified: ${s.profession}',
        );
      } catch (e) {
        debugPrint('Profession achievement grant failed: $e');
      }
    }
    _load();
  }

  Future<void> _reject(VerificationSubmission s) async {
    final notesController = TextEditingController();
    try {
      final confirmed = await showVDialog<bool>(
        context: context,
        title: 'Reject verification?',
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          vDialogActionsRow([
            VButton(
              label: 'Cancel',
              variant: ButtonVariant.text,
              onPressed: () => Navigator.pop(context, false),
            ),
            VButton(
              label: 'Reject',
              onPressed: () => Navigator.pop(context, true),
            ),
          ]),
        ],
      );

      if (confirmed == true) {
        await VerificationService.reject(
          s.id,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );
        _load();
      }
    } finally {
      notesController.dispose();
    }
  }

  // ── Flagged post actions ───────────────────────────────────────

  void _approvePost(Post post) {
    ref.read(postProvider.notifier).editPostStatus(post.id, 'published');
  }

  void _removePost(Post post) {
    ref.read(postProvider.notifier).deletePost(post.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return VHubPage(
      title: 'Staff review',
      showBack: true,
      body: VTabs(
        tabs: [
          VTabEntry(
            label: const Text('Professions'),
            child: _buildVerificationsTab(theme),
          ),
          VTabEntry(
            label: const Text('Achievements'),
            child: _buildAchievementsTab(theme),
          ),
          VTabEntry(
            label: const Text('Flagged Posts'),
            child: _buildFlaggedPostsTab(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationsTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (_loading) return const ScreenLoading.list();
    if (_submissions.isEmpty) {
      return const AppEmptyState(
        title: 'No pending verifications',
        description:
            'Profession reviews will appear here when residents submit proof.',
        icon: Icons.verified_user_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(VSpacing.md),
        itemCount: _submissions.length,
        itemBuilder: (_, i) {
          final s = _submissions[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _submissions.length - 1 ? VSpacing.sm : 0,
            ),
            child: Padding(
              padding: EdgeInsets.zero,
              child: _Card(
                padding: const EdgeInsets.all(VSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                (isDark
                                        ? VColors.primaryContainerDark
                                        : VColors.primaryContainer)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(VRadius.pill),
                          ),
                          child: Icon(
                            Icons.badge_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: VIconSize.md,
                          ),
                        ),
                        const SizedBox(width: VSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.residentName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: VFontWeight.bold,
                                ),
                              ),
                              Text(
                                IdentityVerification.isIdentityProfession(
                                      s.profession,
                                    )
                                    ? 'Identity: ${IdentityVerification.labelForProfession(s.profession)}'
                                    : 'Profession: ${s.profession}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: VColors.error),
                          tooltip: 'Reject',
                          onPressed: () => _reject(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: VColors.success),
                          tooltip: 'Approve',
                          onPressed: () => _approve(s),
                        ),
                      ],
                    ),
                    if (s.proofUrl.isNotEmpty) ...[
                      const SizedBox(height: VSpacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(VRadius.pill),
                        child: Image.network(
                          s.proofUrl,
                          height: 176,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            height: 96,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  (isDark
                                          ? VColors.surfaceContainerDark
                                          : VColors.surfaceContainerLow)
                                      .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(VRadius.pill),
                            ),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _approveAchievement(PendingAchievementSubmission s) async {
    final notesController = TextEditingController();
    try {
      final confirmed = await showVDialog<bool>(
        context: context,
        title: 'Approve achievement?',
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Message for the resident (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          vDialogActionsRow([
            VButton(
              label: 'Cancel',
              variant: ButtonVariant.text,
              onPressed: () => Navigator.pop(context, false),
            ),
            VButton(
              label: 'Approve',
              onPressed: () => Navigator.pop(context, true),
            ),
          ]),
        ],
      );
      if (confirmed != true) return;
      await AchievementReviewService.approve(
        userId: s.userId,
        achievementId: s.achievementId,
        reviewerNotes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
      _loadAchievements();
    } finally {
      notesController.dispose();
    }
  }

  Future<void> _rejectAchievement(PendingAchievementSubmission s) async {
    var reasonCode = achievementRejectReasons.first.code;
    final notesController = TextEditingController();
    final confirmed = await showVDialog<bool>(
      context: context,
      title: 'Reject achievement?',
      content: StatefulBuilder(
        builder: (ctx, setLocal) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reasonCode,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: achievementRejectReasons
                    .map(
                      (r) =>
                          DropdownMenuItem(value: r.code, child: Text(r.label)),
                    )
                    .toList(),
                onChanged: (v) => setLocal(() => reasonCode = v ?? reasonCode),
              ),
              const SizedBox(height: VSpacing.md),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: reasonCode == 'custom'
                      ? 'Your message to the resident'
                      : 'Extra note (optional)',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        vDialogActionsRow([
          VButton(
            label: 'Cancel',
            variant: ButtonVariant.text,
            onPressed: () => Navigator.pop(context, false),
          ),
          VButton(
            label: 'Reject',
            onPressed: () => Navigator.pop(context, true),
          ),
        ]),
      ],
    );
    if (confirmed == true) {
      final note = buildRejectNote(
        reasonCode: reasonCode,
        customNote: notesController.text,
      );
      await AchievementReviewService.reject(
        userId: s.userId,
        achievementId: s.achievementId,
        notes: note,
      );
      _loadAchievements();
    }
    notesController.dispose();
  }

  Widget _buildAchievementsTab(ThemeData theme) {
    if (_achievementsLoading) return const ScreenLoading.list();
    if (_achievementSubmissions.isEmpty) {
      return Column(
        children: [
          if (_queueMetrics != null)
            _VerifierMetricsBar(metrics: _queueMetrics!),
          const Expanded(
            child: AppEmptyState(
              title: 'No pending achievements',
              description:
                  'Submitted achievement proofs (e.g. education, career) appear here.',
              icon: Icons.emoji_events_outlined,
            ),
          ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await _loadAchievements();
        await _loadMetrics();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(VSpacing.md),
        itemCount: _achievementSubmissions.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Column(
              children: [
                if (_queueMetrics != null)
                  _VerifierMetricsBar(metrics: _queueMetrics!),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Compact review mode'),
                  subtitle: const Text('Denser cards for faster triage'),
                  value: _compactVerifierMode,
                  onChanged: (v) => setState(() => _compactVerifierMode = v),
                ),
                const SizedBox(height: VSpacing.sm),
              ],
            );
          }
          final s = _achievementSubmissions[i - 1];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _achievementSubmissions.length ? VSpacing.sm : 0,
            ),
            child: _Card(
              padding: EdgeInsets.all(
                _compactVerifierMode ? VSpacing.sm : VSpacing.md,
              ),
              child: AchievementVerifierReviewCard(
                submission: s,
                compact: _compactVerifierMode,
                onApprove: () => _approveAchievement(s),
                onReject: () => _rejectAchievement(s),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFlaggedPostsTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final postState = ref.watch(postProvider);
    final flaggedPosts = postState.posts
        .where((p) => p.status == 'pending_review' || p.status == 'flagged')
        .toList();

    if (flaggedPosts.isEmpty) {
      return const AppEmptyState(
        title: 'No flagged posts',
        description: 'Posts flagged by The Sentinel will appear here.',
        icon: Icons.shield_outlined,
      );
    }

    return ListView.builder(
      itemCount: flaggedPosts.length,
      padding: const EdgeInsets.all(VSpacing.md),
      itemBuilder: (_, i) {
        final post = flaggedPosts[i];
        return Padding(
          padding: EdgeInsets.only(
            bottom: i < flaggedPosts.length - 1 ? VSpacing.sm : 0,
          ),
          child: _Card(
            padding: const EdgeInsets.all(VSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author + status badge
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: post.residentAvatar.isNotEmpty
                          ? NetworkImage(post.residentAvatar)
                          : null,
                      child: post.residentAvatar.isEmpty
                          ? const Icon(Icons.person, size: VIconSize.sm)
                          : null,
                    ),
                    const SizedBox(width: VSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.residentName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            post.status == 'pending_review'
                                ? 'Pending Review'
                                : 'Flagged',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: post.status == 'pending_review'
                                  ? (isDark
                                        ? VColors.warningContainerDark
                                        : VColors.warning)
                                  : VColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: VColors.error,
                          ),
                          tooltip: 'Remove post',
                          onPressed: () => _removePost(post),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: VColors.success,
                          ),
                          tooltip: 'Approve post',
                          onPressed: () => _approvePost(post),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.sm),
                // Content preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(VSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                  child: Text(
                    post.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (post.hasImages) ...[
                  const SizedBox(height: VSpacing.sm),
                  Text(
                    'Contains ${post.allImageUris.length} image(s)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VerifierMetricsBar extends StatelessWidget {
  final VerifierQueueMetrics metrics;

  const _VerifierMetricsBar({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: VSpacing.sm),
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verifier queue',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            '${metrics.pendingCount} pending · '
            'median wait ${metrics.medianHoursPending.toStringAsFixed(1)}h · '
            'median verify ${metrics.medianHoursToVerify.toStringAsFixed(1)}h (30d)',
            style: theme.textTheme.bodySmall,
          ),
        ],
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
        color: isDark
            ? VColors.surfaceContainerDark
            : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}
