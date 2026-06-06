import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/post.dart';
import '../../state/post_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/haptics.dart';
import 'badge_reaction_picker.dart';
import 'cross_post_achievement_sheet.dart';

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
          _CompactAction(
            icon: activeReactions.contains('heart')
                ? Icons.favorite
                : Icons.favorite_border,
            tooltip: count('heart') > 0 ? 'Like (${count('heart')})' : 'Like',
            active: activeReactions.contains('heart'),
            color: VColors.error,
            onTap: canInteract ? () => _toggle(ref, 'heart') : null,
            badge: count('heart') > 0 ? count('heart') : null,
          ),
          _CompactAction(
            icon: Icons.arrow_upward,
            tooltip: count('upvote') > 0 ? 'Upvote (${count('upvote')})' : 'Upvote',
            active: activeReactions.contains('upvote'),
            onTap: canInteract ? () => _toggle(ref, 'upvote') : null,
            badge: count('upvote') > 0 ? count('upvote') : null,
          ),
          _CompactAction(
            icon: Icons.arrow_downward,
            tooltip:
                count('downvote') > 0 ? 'Downvote (${count('downvote')})' : 'Downvote',
            active: activeReactions.contains('downvote'),
            onTap: canInteract ? () => _toggle(ref, 'downvote') : null,
            badge: count('downvote') > 0 ? count('downvote') : null,
          ),
          if (score != 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.xxs),
              child: Text(
                '$score',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: VFontWeight.bold,
                  color: score > 0 ? VColors.success : VColors.error,
                ),
              ),
            ),
          _CompactAction(
            icon: Icons.chat_bubble_outline,
            tooltip: post.comments.isEmpty
                ? 'Comment'
                : 'Comments (${post.comments.length})',
            onTap: onComment,
            badge: post.comments.isNotEmpty ? post.comments.length : null,
          ),
          _CompactAction(
            icon: Icons.repeat,
            tooltip: 'Repost',
            onTap: canInteract
                ? () {
                    Haptics.light();
                    unawaited(ref.read(postProvider.notifier).repost(post.id));
                  }
                : null,
          ),
          _CompactAction(
            icon: Icons.share_outlined,
            tooltip: 'Share',
            onTap: () {
              final text = post.content.trim();
              SharePlus.instance.share(
                ShareParams(
                  text: text.isEmpty
                      ? 'Check out this post on Vertiege'
                      : '$text\n\n— via Vertiege',
                ),
              );
            },
          ),
          _CompactAction(
            icon: Icons.workspace_premium_outlined,
            tooltip: 'Badge reaction',
            onTap: canInteract
                ? () => BadgeReactionPickerSheet.show(
                      context,
                      reactionKey: (key) => _toggle(ref, key),
                    )
                : null,
          ),
          _CompactAction(
            icon: Icons.send_outlined,
            tooltip: 'Share to world channel',
            onTap: canInteract
                ? () {
                    Haptics.light();
                    showCrossPostAchievementSheet(
                      context,
                      post: post,
                      activeReactions: activeReactions,
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;
  final Color? color;
  final int? badge;

  const _CompactAction({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.active = false,
    this.color,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = active
        ? (color ?? theme.colorScheme.primary)
        : theme.colorScheme.onSurfaceVariant;

    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.sm),
          child: SizedBox(
          width: VTouchTarget.iconButton,
          height: VTouchTarget.iconButton,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: VIconSize.md, color: iconColor),
              if (badge != null)
                Positioned(
                  right: VSpacing.xxs,
                  top: VSpacing.xs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.xs,
                      vertical: VSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(VRadius.pill),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Text(
                      badge! > 99 ? '99+' : '$badge',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: VFontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
