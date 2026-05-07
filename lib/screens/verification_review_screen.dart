import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';
import '../services/verification_service.dart';
import '../state/post_provider.dart';
import '../theme/design_system.dart';
import '../widgets/core/loading_state.dart';

class VerificationReviewScreen extends ConsumerStatefulWidget {
  const VerificationReviewScreen({super.key});

  @override
  ConsumerState<VerificationReviewScreen> createState() =>
      _VerificationReviewScreenState();
}

class _VerificationReviewScreenState
    extends ConsumerState<VerificationReviewScreen>
    with TickerProviderStateMixin {
  List<VerificationSubmission> _submissions = [];
  bool _loading = true;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      await VerificationService.reject(s.id,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim());
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Review'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Verifications'),
            Tab(text: 'Flagged Posts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVerificationsTab(theme),
          _buildFlaggedPostsTab(theme),
        ],
      ),
    );
  }

  Widget _buildVerificationsTab(ThemeData theme) {
    if (_loading) return const GlassLoadingList();
    if (_submissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No pending verifications',
                style: theme.textTheme.bodyLarge),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _submissions.length,
        itemBuilder: (_, i) {
          final s = _submissions[i];
          return Card(
            margin:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.residentName,
                                style: theme.textTheme.titleSmall),
                            Text(s.profession,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                )),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.red),
                            tooltip: 'Reject',
                            onPressed: () => _reject(s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check,
                                color: Colors.green),
                            tooltip: 'Approve',
                            onPressed: () => _approve(s),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (s.proofUrl.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        s.proofUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(),
                      ),
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

  Widget _buildFlaggedPostsTab(ThemeData theme) {
    final postState = ref.watch(postProvider);
    final flaggedPosts = postState.posts
        .where((p) => p.status == 'pending_review' || p.status == 'flagged')
        .toList();

    if (flaggedPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_outlined,
                size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('No flagged posts',
                style: theme.textTheme.bodyLarge),
            const SizedBox(height: 4),
            Text(
              'Posts flagged by The Sentinel will appear here',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: flaggedPosts.length,
      padding: const EdgeInsets.all(Spacing.md),
      itemBuilder: (_, i) {
        final post = flaggedPosts[i];
        return Card(
          margin: EdgeInsets.only(bottom: i < flaggedPosts.length - 1 ? Spacing.sm : 0),
          child: Padding(
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
                          Text(post.residentName,
                              style: theme.textTheme.titleSmall),
                          Text(
                            post.status == 'pending_review'
                                ? 'Pending Review'
                                : 'Flagged',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: post.status == 'pending_review'
                                  ? Colors.orange
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Remove post',
                          onPressed: () => _removePost(post),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.green),
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
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                  ),
                  child: Text(
                    post.content,
                    style: theme.textTheme.bodyMedium,
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
