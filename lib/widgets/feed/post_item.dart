import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/post.dart';
import '../../models/report.dart';
import '../../services/permission_service.dart';
import '../../services/moderation_service.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../utils/date_format.dart';
import '../core/fade_in.dart';
import '../core/glass_sheet.dart';
import '../shared/tier_icon.dart';
import '../profile/cosmetic_avatar.dart';
import '../profile/luminary_nameplate.dart';
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

    final isOwnPost = resident?.id == post.residentId;
    final canMod = _canDelete(ref);
    final canPin = _canPin(ref);
    final showOverflow = canMod || !isOwnPost || canPin || isOwnPost;

    // Build a resident name -> ID map from all posts for mention resolution
    final postState = ref.watch(postProvider);
    final nameToId = <String, String>{};
    for (final p in postState.posts) {
      nameToId[p.residentName] = p.residentId;
    }
    if (resident != null) {
      nameToId[resident.name] = resident.id;
    }

    final isCouncilPost = post.tierAtPosting.value >= 4;

    return FadeIn(
      delayMs: index * 70,
      child: GestureDetector(
        onDoubleTap: () {
          if (resident != null) {
            ref
                .read(postProvider.notifier)
                .addReaction(post.id, '❤️', resident.id);
            HapticFeedback.mediumImpact();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(RadiusTokens.card),
            border: Border(
              left: isCouncilPost
                  ? BorderSide(
                      color: AppColors.tertiary.withValues(alpha: 0.5),
                      width: 3,
                    )
                  : BorderSide(color: AppColors.glassBorder),
              top: BorderSide(color: AppColors.glassBorder),
              right: BorderSide(color: AppColors.glassBorder),
              bottom: BorderSide(color: AppColors.glassBorder),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showResidentPreview(context, ref),
                      onLongPress: () =>
                          context.push('/residents/${post.residentId}'),
                      child: Hero(
                        tag: 'avatar-${post.residentId}',
                        child: CosmeticAvatar(
                          imageUrl: post.residentAvatar,
                          seed: post.residentId,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _showResidentPreview(context, ref),
                            onLongPress: () =>
                                context.push('/residents/${post.residentId}'),
                            child: LuminaryNameplate(
                              name: post.residentName,
                              tier: post.tierAtPosting.value,
                              fontSize: FontSizes.bodyMd,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              TierIcon(
                                tier: post.tierAtPosting.value,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatTimestamp(post.timestamp) +
                                    (post.isEdited ? ' (edited)' : ''),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (showOverflow)
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_horiz,
                          size: 20,
                          color: theme.colorScheme.outline,
                        ),
                        onSelected: (action) {
                          if (action == 'delete') _onDelete(ref);
                          if (action == 'report') _onReport(context, ref);
                          if (action == 'pin') _onTogglePin(ref);
                          if (action == 'edit') _onEdit(context, ref);
                        },
                        itemBuilder: (context) => [
                          if (isOwnPost)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit post'),
                            ),
                          if (canPin)
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(
                                post.isPinned ? 'Unpin post' : 'Pin post',
                              ),
                            ),
                          if (canMod)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete post'),
                            ),
                          if (!isOwnPost)
                            const PopupMenuItem(
                              value: 'report',
                              child: Text('Report'),
                            ),
                        ],
                      ),
                  ],
                ),
                if (post.isPinned || post.isAnnouncement || post.isDecree) ...[
                  const SizedBox(height: 8),
                  if (post.isDecree) _DecreeLabel(),
                  if (post.isPinned && !post.isDecree)
                    Row(
                      children: [
                        Icon(
                          Icons.push_pin,
                          size: 14,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Pinned',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeights.bold,
                          ),
                        ),
                      ],
                    ),
                  if (post.isAnnouncement)
                    Row(
                      children: [
                        Icon(
                          Icons.campaign,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Announcement',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeights.bold,
                          ),
                        ),
                      ],
                    ),
                ],
                Padding(
                  padding: EdgeInsets.only(
                    top: post.isPinned || post.isAnnouncement ? 6 : 8,
                    bottom: post.imageUri != null || post.poll != null ? 8 : 0,
                  ),
                  child: _RichPostContent(
                    content: post.content,
                    theme: theme,
                    onMentionTap: (name) {
                      final id = nameToId[name];
                      if (id != null) {
                        context.push('/residents/$id');
                      }
                    },
                    onHashtagTap: (tag) => context.push('/search?q=%23$tag'),
                  ),
                ),
                // ── Poll display ──
                if (post.poll != null) ...[
                  const SizedBox(height: 8),
                  _PollDisplay(post: post),
                ],
                if (post.imageUri != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        post.imageUri!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
                IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: ReactionBar(
                          reactions: post.reactions,
                          currentResidentId: resident?.id ?? '',
                          onReact: (emoji) {
                            ref
                                .read(postProvider.notifier)
                                .addReaction(
                                  post.id,
                                  emoji,
                                  resident?.id ?? '',
                                );
                          },
                        ),
                      ),
                      if (post.comments.isNotEmpty) ...[
                        Container(width: 1, color: theme.dividerColor),
                        GestureDetector(
                          onTap: () => _showComments(context, ref),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 16,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.comments.length}',
                                  style: theme.textTheme.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canDelete(WidgetRef ref) {
    final resident = ref.read(residentProvider).resident;
    if (resident == null || worldId == null) return false;
    return WorldPermissions.canDeletePost(
      resident,
      worldId!,
      post.residentId,
      null,
    );
  }

  bool _canPin(WidgetRef ref) {
    final resident = ref.read(residentProvider).resident;
    if (resident == null || worldId == null) return false;
    return WorldPermissions.canModerate(resident, worldId!, null);
  }

  void _onTogglePin(WidgetRef ref) {
    ref.read(postProvider.notifier).togglePin(post.id);
  }

  void _onEdit(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController(text: post.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit post'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                ref.read(postProvider.notifier).editPost(post.id, text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResidentPreview(BuildContext context, WidgetRef ref) {
    final resident = ref.read(residentProvider).resident;
    final isOwn = resident?.id == post.residentId;
    final isFollowing = ref
        .read(residentProvider.notifier)
        .isFollowing(post.residentId);
    final tierLabel = post.tierAtPosting.label;

    showGlassSheet(
      context,
      Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: Spacing.lg),
            CosmeticAvatar(
              imageUrl: post.residentAvatar,
              seed: post.residentId,
              size: 72,
            ),
            const SizedBox(height: Spacing.md),
            LuminaryNameplate(
              name: post.residentName,
              tier: post.tierAtPosting.value,
              fontSize: FontSizes.headlineMd,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              tierLabel,
              style: const TextStyle(
                fontSize: FontSizes.bodyMd,
                fontWeight: FontWeights.semiBold,
                color: AppColors.tertiary,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            if (!isOwn)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      final notifier = ref.read(residentProvider.notifier);
                      if (isFollowing) {
                        notifier.unfollow(post.residentId);
                      } else {
                        notifier.follow(post.residentId);
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFollowing
                                ? 'Unfollowed ${post.residentName}'
                                : 'Following ${post.residentName}',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      isFollowing ? Icons.person_remove : Icons.person_add,
                      size: IconSizes.sm,
                    ),
                    label: Text(isFollowing ? 'Unfollow' : 'Follow'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      foregroundColor: AppColors.onTertiary,
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to full profile on second tap
                      context.push('/residents/${post.residentId}');
                    },
                    icon: const Icon(Icons.person, size: IconSizes.sm),
                    label: const Text('View Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.glassBorder),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/residents/${post.residentId}');
                },
                icon: const Icon(Icons.person, size: IconSizes.sm),
                label: const Text('View My Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
              ),
            const SizedBox(height: Spacing.lg),
          ],
        ),
      ),
      initialSize: 0.55,
    );
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
          ModerationService.submitReport(
            worldId: post.worldId,
            postId: post.id,
            reporterId: resident.id,
            reason: reason.name,
            details: details,
          );
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
              onPressed: () => widget.onSubmit(
                _reason,
                _detailsController.text.trim().isEmpty
                    ? null
                    : _detailsController.text.trim(),
              ),
              child: const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rich post content that renders @mentions and #hashtags as tappable spans.
class _RichPostContent extends StatefulWidget {
  final String content;
  final ThemeData theme;
  final void Function(String name)? onMentionTap;
  final void Function(String tag)? onHashtagTap;

  const _RichPostContent({
    required this.content,
    required this.theme,
    this.onMentionTap,
    this.onHashtagTap,
  });

  @override
  State<_RichPostContent> createState() => _RichPostContentState();
}

class _RichPostContentState extends State<_RichPostContent> {
  static const int _truncateAt = 280;
  bool _expanded = false;

  bool get _isLong => widget.content.length > _truncateAt;

  InlineSpan _buildRichText(String text) {
    final textStyle = widget.theme.textTheme.bodyMedium?.copyWith(height: 1.4);
    final mentionStyle = textStyle?.copyWith(
      color: AppColors.tertiary,
      fontWeight: FontWeights.semiBold,
    );
    final hashtagStyle = textStyle?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeights.semiBold,
    );
    final boldStyle = textStyle?.copyWith(fontWeight: FontWeights.bold);
    final italicStyle = textStyle?.copyWith(fontStyle: FontStyle.italic);

    // Unified pattern: bold (**...**), italic (*...*), @mention, #hashtag
    final combined = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|@(\w+)|#(\w+)');
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in combined.allMatches(text)) {
      // Add plain text before this match
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(TextSpan(text: match.group(1)!, style: boldStyle));
      } else if (match.group(2) != null) {
        // *italic*
        spans.add(TextSpan(text: match.group(2)!, style: italicStyle));
      } else if (match.group(3) != null) {
        // @mention
        final name = match.group(3)!;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => widget.onMentionTap?.call(name),
              child: Text('@$name', style: mentionStyle),
            ),
          ),
        );
      } else if (match.group(4) != null) {
        // #hashtag
        final tag = match.group(4)!;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => widget.onHashtagTap?.call(tag.toLowerCase()),
              child: Text('#${tag.toLowerCase()}', style: hashtagStyle),
            ),
          ),
        );
      }

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return TextSpan(style: textStyle, children: spans);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLong) {
      return RichText(text: _buildRichText(widget.content));
    }

    final displayText = _expanded
        ? widget.content
        : '${widget.content.substring(0, _truncateAt)}...';

    return AnimatedSize(
      duration: AnimDurations.normal,
      curve: AnimCurves.easeInOut,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(text: _buildRichText(displayText)),
          const SizedBox(height: Spacing.xs),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'See more...',
              style: widget.theme.textTheme.labelMedium?.copyWith(
                color: widget.theme.colorScheme.primary,
                fontWeight: FontWeights.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Poll display widget with animated vote fill.
class _PollDisplay extends ConsumerWidget {
  final Post post;
  const _PollDisplay({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poll = post.poll;
    if (poll == null) return const SizedBox.shrink();

    final resident = ref.watch(residentProvider).resident;
    final hasVoted =
        resident != null && poll.votedResidentIds.contains(resident.id);
    final totalVotes = poll.totalVotes;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: const TextStyle(
              fontSize: FontSizes.headlineMd,
              fontWeight: FontWeights.semiBold,
              color: AppColors.ink,
            ),
          ),
          if (poll.isMultiChoice)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: Text(
                'Choose as many as you like',
                style: TextStyle(
                  fontSize: FontSizes.labelSm,
                  color: AppColors.inkMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: Spacing.sm),
          ...poll.options.map((option) {
            final percentage = totalVotes > 0
                ? (option.voteCount / totalVotes)
                : 0.0;
            final isSelected = hasVoted && option.voteCount > 0;
            final showResults = hasVoted;

            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: GestureDetector(
                onTap: hasVoted
                    ? null
                    : () => ref
                          .read(postProvider.notifier)
                          .voteOnPoll(post.id, option.id),
                child: AnimatedContainer(
                  duration: AnimDurations.slow,
                  curve: AnimCurves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.glassBackground,
                    borderRadius: BorderRadius.circular(RadiusTokens.chip),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.tertiary
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Animated fill bar
                      if (showResults || hasVoted)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: AnimatedContainer(
                            duration: AnimDurations.slow,
                            curve: AnimCurves.easeInOut,
                            width: percentage > 0
                                ? (MediaQuery.of(context).size.width - 120) *
                                      percentage
                                : 0,
                            decoration: BoxDecoration(
                              color: AppColors.tertiary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                RadiusTokens.chip,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option.text,
                                style: TextStyle(
                                  fontSize: FontSizes.bodyMd,
                                  fontWeight: FontWeights.regular,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            if (showResults) ...[
                              Text(
                                '${option.voteCount} vote${option.voteCount != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: FontSizes.labelSm,
                                  color: AppColors.inkSecondary,
                                ),
                              ),
                              const SizedBox(width: Spacing.xs),
                              Text(
                                '${(percentage * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: FontSizes.labelSm,
                                  fontWeight: FontWeights.semiBold,
                                  color: AppColors.tertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(top: Spacing.xs),
            child: Text(
              '$totalVotes vote${totalVotes != 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: FontSizes.labelSm,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Glowing "SOVEREIGN DECREE" label with pulsing gold animation.
class _DecreeLabel extends StatefulWidget {
  @override
  State<_DecreeLabel> createState() => _DecreeLabelState();
}

class _DecreeLabelState extends State<_DecreeLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.tertiary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(RadiusTokens.chip),
            border: Border.all(
              color: AppColors.tertiary.withValues(
                alpha: 0.3 + (0.15 * _controller.value),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.tertiary.withValues(
                  alpha: 0.15 + (0.2 * _controller.value),
                ),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 14, color: AppColors.tertiary),
              SizedBox(width: 4),
              Text(
                'SOVEREIGN DECREE',
                style: TextStyle(
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.bold,
                  color: AppColors.tertiary,
                  letterSpacing: LetterSpacing.label,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
