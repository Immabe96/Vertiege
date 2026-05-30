import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../config/achievement_reject_reasons.dart';
import '../config/achievements.dart';
import '../services/gamification_service.dart';
import '../services/verification_service.dart';
import '../services/achievement_review_service.dart';
import '../widgets/achievements/achievement_verifier_review_card.dart';
import '../state/post_provider.dart';
import '../theme/v_colors.dart';
import '../forui/v_hub_page.dart';
import '../theme/v_tokens.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
    _loadAchievements();
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
    await VerificationService.approve(s.id, s.residentId, s.profession);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject verification?'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
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
      body: FTabs(
        expands: true,
        control: const FTabControl.managed(),
        children: [
          FTabEntry(
            label: const Text('Professions'),
            child: _buildVerificationsTab(theme),
          ),
          FTabEntry(
            label: const Text('Achievements'),
            child: _buildAchievementsTab(theme),
          ),
          FTabEntry(label: const Text('Flagged Posts'), child: _buildFlaggedPostsTab(theme)),
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
                            color: (isDark
                                    ? VColors.primaryContainerDark
                                    : VColors.primaryContainer)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              VRadius.pill,
                            ),
                          ),
                          child: Icon(
                            Icons.badge_outlined,
                            color: VColors.primary,
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
                                  color: isDark
                                      ? VColors.onSurfaceDark
                                      : VColors.onSurface,
                                  fontWeight: VFontWeight.bold,
                                ),
                              ),
                              Text(
                                s.profession,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: VColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: VColors.error,
                          ),
                          tooltip: 'Reject',
                          onPressed: () => _reject(s),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.check,
                            color: VColors.success,
                          ),
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
                              color: (isDark
                                      ? VColors.surfaceContainerDark
                                      : VColors.surfaceContainerLow)
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(
                                VRadius.pill,
                              ),
                            ),
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve achievement?'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Message for the resident (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AchievementReviewService.approve(
      userId: s.userId,
      achievementId: s.achievementId,
      reviewerNotes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
    );
    notesController.dispose();
    _loadAchievements();
  }

  Future<void> _rejectAchievement(PendingAchievementSubmission s) async {
    var reasonCode = achievementRejectReasons.first.code;
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Reject achievement?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  value: reasonCode,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                  ),
                  items: achievementRejectReasons
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.code,
                          child: Text(r.label),
                        ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
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
      return const AppEmptyState(
        title: 'No pending achievements',
        description:
            'Submitted achievement proofs (e.g. education, career) appear here.',
        icon: Icons.emoji_events_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAchievements,
      child: ListView.builder(
        padding: const EdgeInsets.all(VSpacing.md),
        itemCount: _achievementSubmissions.length,
        itemBuilder: (_, i) {
          final s = _achievementSubmissions[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _achievementSubmissions.length - 1 ? VSpacing.sm : 0,
            ),
            child: _Card(
              padding: const EdgeInsets.all(VSpacing.md),
              child: AchievementVerifierReviewCard(
                submission: s,
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
                          ? const Icon(Icons.person, size: 16)
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
                              color: isDark
                                  ? VColors.onSurfaceDark
                                  : VColors.onSurface,
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
                            icon: Icon(
                              Icons.delete_outline,
                              color: VColors.error,
                            ),
                            tooltip: 'Remove post',
                            onPressed: () => _removePost(post),
                          ),
                          IconButton(
                            icon: Icon(
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
                      color: isDark
                          ? VColors.onSurfaceDark
                          : VColors.onSurface,
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
