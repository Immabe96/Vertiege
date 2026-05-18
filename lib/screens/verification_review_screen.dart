import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../services/verification_service.dart';
import '../state/post_provider.dart';
import '../theme/v_colors.dart';
import '../theme/design_system.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/glass_panel.dart';
import '../widgets/core/loading_state.dart';

class VerificationReviewScreen extends ConsumerStatefulWidget {
  const VerificationReviewScreen({super.key});

  @override
  ConsumerState<VerificationReviewScreen> createState() =>
      _VerificationReviewScreenState();
}

class _VerificationReviewScreenState
    extends ConsumerState<VerificationReviewScreen> {
  List<VerificationSubmission> _submissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  Future<void> _approve(VerificationSubmission s) async {
    await VerificationService.approve(s.id, s.residentId, s.profession);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        title: const Text('Verification Review'),

      ),
      body: FTabs(
        expands: true,
        control: const FTabControl.managed(),
        children: [
          FTabEntry(label: const Text('Verifications'), child: _buildVerificationsTab(theme)),
          FTabEntry(label: const Text('Flagged Posts'), child: _buildFlaggedPostsTab(theme)),
        ],
      ),
    );
  }

  Widget _buildVerificationsTab(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    if (_loading) return const GlassLoadingList();
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
        padding: const EdgeInsets.all(Spacing.md),
        itemCount: _submissions.length,
        itemBuilder: (_, i) {
          final s = _submissions[i];
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _submissions.length - 1 ? Spacing.sm : 0,
            ),
            child: Padding(
              padding: EdgeInsets.zero,
              child: GlassPanel(
                padding: const EdgeInsets.all(Spacing.md),
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
                              RadiusTokens.full,
                            ),
                          ),
                          child: Icon(
                            Icons.badge_outlined,
                            color: VColors.primary,
                            size: IconSizes.md,
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
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
                                  fontWeight: FontWeights.bold,
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
                      const SizedBox(height: Spacing.md),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(RadiusTokens.full),
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
                                RadiusTokens.full,
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
      padding: const EdgeInsets.all(Spacing.md),
      itemBuilder: (_, i) {
        final post = flaggedPosts[i];
        return Padding(
          padding: EdgeInsets.only(
            bottom: i < flaggedPosts.length - 1 ? Spacing.sm : 0,
          ),
          child: GlassPanel(
            padding: const EdgeInsets.all(Spacing.md),
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
                    const SizedBox(width: Spacing.sm),
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
                const SizedBox(height: Spacing.sm),
                // Content preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
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
                  const SizedBox(height: Spacing.sm),
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
