import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/post.dart';
import '../../models/report.dart';
import '../../services/permission_service.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../utils/date_format.dart';
import '../core/fade_in.dart';
import '../shared/tier_icon.dart';
import 'post_image.dart';
import 'comment_sheet.dart';
import 'reaction_bar.dart';

class PostItem extends ConsumerWidget {
  final Post post;
  final int index;
  final String? worldId;

  const PostItem({super.key, required this.post, this.index = 0, this.worldId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resident = ref.watch(residentProvider).resident;

    return FadeIn(
      delayMs: index * 70,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/residents/${post.residentId}'),
                    child: Hero(
                      tag: 'avatar-${post.residentId}',
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(post.residentAvatar),
                        radius: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/residents/${post.residentId}'),
                          child: Text(post.residentName, style: theme.textTheme.labelLarge),
                        ),
                        Row(
                          children: [
                            TierIcon(tier: post.tierAtPosting.value, size: 14),
                            const SizedBox(width: 4),
                            Text(formatTimestamp(post.timestamp), style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_canDelete(ref) || resident?.id != post.residentId)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: theme.colorScheme.outline),
                      onSelected: (action) {
                        if (action == 'delete') _onDelete(ref);
                        if (action == 'report') _onReport(context, ref);
                      },
                      itemBuilder: (context) => [
                        if (_canDelete(ref))
                          const PopupMenuItem(value: 'delete', child: Text('Delete post')),
                        if (resident?.id != post.residentId)
                          const PopupMenuItem(value: 'report', child: Text('Report')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (post.isAnnouncement)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.campaign, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Announcement',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(post.content, style: theme.textTheme.bodyMedium),
              if (post.imageUri != null) ...[
                const SizedBox(height: 8),
                PostImage(uri: post.imageUri!),
              ],
              const SizedBox(height: 8),
              ReactionBar(
                reactions: post.reactions,
                currentResidentId: resident?.id ?? '',
                onReact: (emoji) {
                  ref.read(postProvider.notifier).addReaction(post.id, emoji, resident?.id ?? '');
                },
              ),
              if (post.comments.isNotEmpty) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => _showComments(context, ref),
                  child: Text('View ${post.comments.length} comments'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _canDelete(WidgetRef ref) {
    final resident = ref.read(residentProvider).resident;
    if (resident == null || worldId == null) return false;
    return WorldPermissions.canDeletePost(resident, worldId!, post.residentId, null);
  }

  void _onDelete(WidgetRef ref) {
    ref.read(postProvider.notifier).deletePost(post.id);
  }

  void _onReport(BuildContext context, WidgetRef ref) {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => _ReportSheet(
        onSubmit: (reason, details) {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted. Thank you.')),
          );
        },
      ),
    );
  }

  void _showComments(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CommentSheet(
        comments: post.comments,
        onSubmit: (content) {
          final resident = ref.read(residentProvider).resident;
          if (resident == null) return;
          final comment = Comment(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            residentId: resident.id,
            residentName: resident.name,
            content: content,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );
          ref.read(postProvider.notifier).addComment(post.id, comment);
        },
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  final void Function(ReportReason reason, String? details) onSubmit;

  const _ReportSheet({required this.onSubmit});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason _reason = ReportReason.spam;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report post', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ReportReason.values.map((r) {
              final selected = _reason == r;
              return ChoiceChip(
                label: Text(r.name[0].toUpperCase() + r.name.substring(1)),
                selected: selected,
                onSelected: (_) => setState(() => _reason = r),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detailsController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Additional details (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => widget.onSubmit(_reason, _detailsController.text.trim().isEmpty ? null : _detailsController.text.trim()),
              child: const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }
}
