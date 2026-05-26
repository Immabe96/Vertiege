import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/post.dart';
import '../../state/post_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';
import 'badge_reaction_picker.dart';

/// Primary post actions: like, vote, comment, repost, share, badge react.
class PostActionBar extends ConsumerWidget {
  final Post post;
  final String? residentId;
  final VoidCallback onComment;
  final Set<String> activeReactions;

  const PostActionBar({
    super.key,
    required this.post,
    required this.residentId,
    required this.onComment,
    required this.activeReactions,
  });

  void _toggle(WidgetRef ref, String key) {
    final id = residentId;
    if (id == null || id.isEmpty) return;
    Haptics.light();
    ref.read(postProvider.notifier).toggleReaction(post.id, key, id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canInteract = residentId != null && residentId!.isNotEmpty;

    int count(String key) => post.reactions[key] ?? 0;
    final score = count('upvote') - count('downvote');

    return Padding(
      padding: const EdgeInsets.only(top: VSpacing.xs),
      child: Row(
        children: [
          _ActionButton(
            icon: activeReactions.contains('heart')
                ? Icons.favorite
                : Icons.favorite_border,
            label: count('heart') > 0 ? '${count('heart')}' : 'Like',
            active: activeReactions.contains('heart'),
            color: VColors.error,
            onTap: canInteract ? () => _toggle(ref, 'heart') : null,
          ),
          _ActionButton(
            icon: Icons.arrow_upward,
            label: count('upvote') > 0 ? '${count('upvote')}' : 'Up',
            active: activeReactions.contains('upvote'),
            onTap: canInteract ? () => _toggle(ref, 'upvote') : null,
          ),
          _ActionButton(
            icon: Icons.arrow_downward,
            label: count('downvote') > 0 ? '${count('downvote')}' : 'Down',
            active: activeReactions.contains('downvote'),
            onTap: canInteract ? () => _toggle(ref, 'downvote') : null,
          ),
          if (score != 0)
            Padding(
              padding: const EdgeInsets.only(right: VSpacing.xs),
              child: Text(
                '$score',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: VFontWeight.bold,
                  color: score > 0 ? VColors.success : VColors.error,
                ),
              ),
            ),
          _ActionButton(
            icon: Icons.chat_bubble_outline,
            label: post.comments.isEmpty
                ? 'Comment'
                : '${post.comments.length}',
            onTap: onComment,
          ),
          _ActionButton(
            icon: Icons.repeat,
            label: 'Repost',
            onTap: canInteract
                ? () {
                    Haptics.light();
                    ref.read(postProvider.notifier).repost(post.id);
                  }
                : null,
          ),
          _ActionButton(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () {
              final text = post.content.trim();
              Share.share(
                text.isEmpty
                    ? 'Check out this post on Vertiege'
                    : '$text\n\n— via Vertiege',
              );
            },
          ),
          _ActionButton(
            icon: Icons.workspace_premium_outlined,
            label: 'Badge',
            onTap: canInteract
                ? () => BadgeReactionPickerSheet.show(
                      context,
                      reactionKey: (key) => _toggle(ref, key),
                    )
                : null,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = active
        ? (color ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  color: iconColor,
                  fontWeight: active ? VFontWeight.semiBold : VFontWeight.regular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
