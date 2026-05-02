import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/post.dart';
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
                  if (_canDelete(ref))
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                      tooltip: 'Delete post',
                      onPressed: () => _onDelete(ref),
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
