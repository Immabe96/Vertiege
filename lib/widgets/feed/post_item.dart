import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../router/world_navigation.dart';
import '../../models/post.dart';
import '../../config/awards.dart';
import '../../services/permission_service.dart';
import '../../services/moderation_service.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/date_format.dart';
import '../core/fade_in.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/icons/v_icons.dart';
import '../core/glass_sheet.dart';
import '../core/tier_badge.dart';
import '../report_sheet.dart';
import '../shared/tier_icon.dart';
import '../profile/cosmetic_avatar.dart';
import '../profile/luminary_nameplate.dart';
import 'comment_sheet.dart';
import 'post_action_bar.dart';
import 'reaction_bar.dart';
import '../core/tab_aware_sheet.dart';
import '../../state/world_mute_provider.dart';
import 'heart_animation.dart';
import 'post_image.dart';
import '../../utils/verified_moment.dart';
import '../../widgets/core/v_feedback.dart';
import 'verified_moment_badge.dart';

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
    final isVerifiedMoment = isVerifiedMomentPost(post);

    return FadeIn(
      delayMs: index * 70,
      child: GestureDetector(
        onDoubleTapDown: (details) {
          if (resident != null) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              final position = box.localToGlobal(details.localPosition);
              HeartAnimationOverlay.show(context, position);
            }
            ref
                .read(postProvider.notifier)
                .toggleReaction(post.id, 'heart', resident.id);
            HapticFeedback.mediumImpact();
          }
        },
        onDoubleTap: () {
          if (resident != null) {
            ref
                .read(postProvider.notifier)
                .toggleReaction(post.id, 'heart', resident.id);
            HapticFeedback.mediumImpact();
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: VSpacing.md,
            vertical: VSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: isVerifiedMoment
                ? VColors.brand.withValues(alpha: 0.06)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(VRadius.lg),
            border: Border(
              left: isVerifiedMoment
                  ? const BorderSide(color: VColors.brand, width: 3)
                  : isCouncilPost
                  ? BorderSide(
                      color: VColors.tertiary.withValues(alpha: 0.5),
                      width: 3,
                    )
                  : BorderSide(color: theme.colorScheme.outlineVariant),
              top: BorderSide(
                color: isVerifiedMoment
                    ? VColors.brand.withValues(alpha: 0.25)
                    : theme.colorScheme.outlineVariant,
              ),
              right: BorderSide(
                color: isVerifiedMoment
                    ? VColors.brand.withValues(alpha: 0.25)
                    : theme.colorScheme.outlineVariant,
              ),
              bottom: BorderSide(
                color: isVerifiedMoment
                    ? VColors.brand.withValues(alpha: 0.25)
                    : theme.colorScheme.outlineVariant,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              VSpacing.md,
              VSpacing.md,
              VSpacing.sm,
              VSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isVerifiedMoment) ...[
                  const VerifiedMomentBadge(),
                  const SizedBox(height: VSpacing.sm),
                ],
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showResidentPreview(context, ref),
                      onLongPress: () =>
                          context.push(residentProfilePath(post.residentId)),
                      child: Hero(
                        tag: 'avatar-${post.residentId}',
                        child: CosmeticAvatar(
                          imageUrl: post.residentAvatar,
                          seed: post.residentId,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(width: VSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _showResidentPreview(context, ref),
                            onLongPress: () =>
                                context.push(residentProfilePath(post.residentId)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LuminaryNameplate(
                                  name: post.feedAuthorLabel,
                                  tier: post.tierAtPosting.value,
                                  fontSize: VFontSize.bodyMd,
                                ),
                                const SizedBox(width: VSpacing.xs),
                                TierBadge(tier: post.tierAtPosting.value),
                              ],
                            ),
                          ),
                          const SizedBox(height: VSpacing.xxs),
                          Row(
                            children: [
                              TierIcon(
                                tier: post.tierAtPosting.value,
                                size: VIconSize.xs,
                              ),
                              const SizedBox(width: VSpacing.xs),
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
                          size: VIconSize.md,
                          color: theme.colorScheme.outline,
                        ),
                        onSelected: (action) {
                          if (action == 'delete') _onDelete(ref);
                          if (action == 'report') _onReport(context, ref);
                          if (action == 'pin') _onTogglePin(ref);
                          if (action == 'edit') _onEdit(context, ref);
                          if (action == 'mute') _onMuteWorld(context, ref);
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
                          if (post.worldId.isNotEmpty)
                            PopupMenuItem(
                              value: 'mute',
                              child: Text(
                                ref.watch(worldMuteProvider).contains(post.worldId)
                                    ? 'Unmute world notifications'
                                    : 'Mute world notifications',
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
                if (post.isPinned || post.isAnnouncement || post.isDecree) ...[
                  const SizedBox(height: VSpacing.sm),
                  if (post.isDecree) _DecreeLabel(),
                  if (post.isPinned && !post.isDecree)
                    Row(
                      children: [
                        Icon(
                          Icons.push_pin,
                          size: VIconSize.denseSm,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: VSpacing.xs),
                        Text(
                          'Pinned',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: VFontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  if (post.isAnnouncement)
                    Row(
                      children: [
                        Icon(
                          Icons.campaign,
                          size: VIconSize.denseSm,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: VSpacing.xs),
                        Text(
                          'Announcement',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: VFontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
                Padding(
                  padding: EdgeInsets.only(
                    top: post.isPinned || post.isAnnouncement
                        ? VSpacing.xs
                        : VSpacing.sm,
                    bottom: post.imageUri != null || post.poll != null
                        ? VSpacing.sm
                        : 0,
                  ),
                  child: _RichPostContent(
                    content: post.content,
                    theme: theme,
                    onMentionTap: (name) {
                      final id = nameToId[name];
                      if (id != null) {
                        context.push(residentProfilePath(id));
                      }
                    },
                    onHashtagTap: (tag) => context.push('/search?q=%23$tag'),
                  ),
                ),
                // ── Poll display ──
                if (post.poll != null) ...[
                  const SizedBox(height: VSpacing.sm),
                  _PollDisplay(post: post),
                ],
                if (post.allImageUris.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: VSpacing.md),
                    child: Transform.translate(
                      offset: const Offset(-VSpacing.md, 0),
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        child: post.allImageUris.length == 1
                            ? PostImage(
                                uri: post.allImageUris.first,
                                borderRadius: BorderRadius.zero,
                              )
                            : _ImageCarousel(
                                imageUris: post.allImageUris,
                                edgeToEdge: true,
                              ),
                      ),
                    ),
                  ),
                ],
                if (post.awards.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: VSpacing.sm),
                    child: Wrap(
                      spacing: VSpacing.xs,
                      runSpacing: VSpacing.xs,
                      children: post.awards.map((awardKey) {
                        final awardTypeId = awardKey.split(':').first;
                        final meta = AwardType.all[awardTypeId];
                        if (meta == null) return const SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: VSpacing.xs, vertical: VSpacing.xxs),
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(VRadius.pill),
                            border: Border.all(color: theme.colorScheme.outlineVariant),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(meta.icon, style: const TextStyle(fontSize: VFontSize.labelMd)),
                              const SizedBox(width: VSpacing.xxs),
                              Text(meta.label, style: TextStyle(fontSize: VFontSize.labelSm, color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                PostActionBar(
                  post: post,
                  residentId: resident?.id,
                  activeReactions: ref
                      .read(postProvider.notifier)
                      .userReactionsForPost(post.id),
                  onComment: () => _showComments(context, ref),
                ),
                if (post.reactions.isNotEmpty) ...[
                  const SizedBox(height: VSpacing.xs),
                  ReactionBar(
                    reactions: post.reactions,
                    currentResidentId: resident?.id ?? '',
                    userTier: resident?.tier.value ?? 1,
                    activeReactions: ref
                        .read(postProvider.notifier)
                        .userReactionsForPost(post.id),
                    onReact: (key) {
                      if (resident == null) return;
                      ref.read(postProvider.notifier).toggleReaction(
                            post.id,
                            key,
                            resident.id,
                          );
                    },
                  ),
                ],
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
    showTabAwareDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit post'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(ctx),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Save',
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                ref.read(postProvider.notifier).editPost(post.id, text);
                Navigator.pop(ctx);
              }
            },
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

    showAppSheet(
      context,
      Padding(
        padding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: VSpacing.lg),
            CosmeticAvatar(
              imageUrl: post.residentAvatar,
              seed: post.residentId,
              size: 72,
            ),
            const SizedBox(height: VSpacing.md),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                LuminaryNameplate(
                  name: post.feedAuthorLabel,
                  tier: post.tierAtPosting.value,
                  fontSize: VFontSize.headlineMd,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(width: VSpacing.xs),
                TierBadge(tier: post.tierAtPosting.value, size: VIconSize.md),
              ],
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              tierLabel,
              style: const TextStyle(
                fontSize: VFontSize.bodyMd,
                fontWeight: VFontWeight.semiBold,
                color: VColors.tertiary,
              ),
            ),
            const SizedBox(height: VSpacing.lg),
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
                      VFeedback.showMessage(context, isFollowing
                                ? 'Unfollowed ${post.residentName}'
                                : 'Following ${post.residentName}',);
                    },
                    icon: Icon(
                      isFollowing ? Icons.person_remove : Icons.person_add,
                      size: VIconSize.sm,
                    ),
                    label: Text(isFollowing ? 'Unfollow' : 'Follow'),
                    style: FilledButton.styleFrom(
                      backgroundColor: VColors.tertiary,
                      foregroundColor: VColors.onTertiary,
                    ),
                  ),
                  const SizedBox(width: VSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to full profile on second tap
                      context.push(residentProfilePath(post.residentId));
                    },
                    icon: const Icon(VIcons.user, size: VIconSize.sm),
                    label: const Text('View Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(residentProfilePath(post.residentId));
                },
                icon: const Icon(VIcons.user, size: VIconSize.sm),
                label: const Text('View My Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
              ),
            const SizedBox(height: VSpacing.lg),
          ],
        ),
      ),
      initialSize: 0.55,
    );
  }

  void _onDelete(WidgetRef ref) {
    ref.read(postProvider.notifier).deletePost(post.id);
  }

  void _onMuteWorld(BuildContext context, WidgetRef ref) {
    if (post.worldId.isEmpty) return;
    ref.read(worldMuteProvider.notifier).toggle(post.worldId);
    final muted = ref.read(worldMuteProvider).contains(post.worldId);
    VFeedback.showMessage(
      context,
      muted
          ? 'Notifications muted for this world'
          : 'Notifications restored for this world',
    );
  }

  void _onReport(BuildContext context, WidgetRef ref) {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;
    ReportSheet.show(
      context,
      targetLabel: 'post',
      onSubmit: (reason, details) {
        Navigator.pop(context);
        ModerationService.submitReport(
          worldId: post.worldId,
          postId: post.id,
          reporterId: resident.id,
          reason: reason.name,
          details: details,
        );
        VFeedback.showMessage(context, 'Report submitted. Thank you.');
      },
    );
  }

  void _showComments(BuildContext context, WidgetRef ref) {
    openPostComments(context, postId: post.id);
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
      color: VColors.tertiary,
      fontWeight: VFontWeight.semiBold,
    );
    final hashtagStyle = textStyle?.copyWith(
      color: widget.theme.colorScheme.primary,
      fontWeight: VFontWeight.semiBold,
    );
    final boldStyle = textStyle?.copyWith(fontWeight: VFontWeight.bold);
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
      duration: VAnimation.normal,
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(text: _buildRichText(displayText)),
          const SizedBox(height: VSpacing.xs),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Show less' : 'See more...',
              style: widget.theme.textTheme.labelMedium?.copyWith(
                color: widget.theme.colorScheme.primary,
                fontWeight: VFontWeight.bold,
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(VRadius.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            poll.question,
            style: TextStyle(
              fontSize: VFontSize.headlineMd,
              fontWeight: VFontWeight.semiBold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (poll.isMultiChoice)
            Padding(
              padding: const EdgeInsets.only(top: VSpacing.xs),
              child: Text(
                'Choose as many as you like',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: VSpacing.sm),
          ...poll.options.map((option) {
            final percentage = totalVotes > 0
                ? (option.voteCount / totalVotes)
                : 0.0;
            final isSelected = hasVoted && option.voteCount > 0;
            final showResults = hasVoted;

            return Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.sm),
              child: GestureDetector(
                onTap: hasVoted
                    ? null
                    : () => ref
                          .read(postProvider.notifier)
                          .voteOnPoll(post.id, option.id),
                child: AnimatedContainer(
                  duration: VAnimation.slow,
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.md,
                    vertical: VSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(VRadius.sm),
                    border: Border.all(
                      color: isSelected
                          ? VColors.tertiary
                          : theme.colorScheme.outlineVariant,
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
                            duration: VAnimation.slow,
                            curve: Curves.easeInOutCubic,
                            width: percentage > 0
                                ? (MediaQuery.of(context).size.width - 120) *
                                      percentage
                                : 0,
                            decoration: BoxDecoration(
                              color: VColors.tertiary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                VRadius.sm,
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
                                  fontSize: VFontSize.bodyMd,
                                  fontWeight: VFontWeight.regular,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (showResults) ...[
                              Text(
                                '${option.voteCount} vote${option.voteCount != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: VFontSize.labelSm,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: VSpacing.xs),
                              Text(
                                '${(percentage * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: VFontSize.labelSm,
                                  fontWeight: VFontWeight.semiBold,
                                  color: VColors.tertiary,
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
            padding: const EdgeInsets.only(top: VSpacing.xs),
            child: Text(
              '$totalVotes vote${totalVotes != 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: VFontSize.labelSm,
                color: theme.colorScheme.outline,
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
            horizontal: VSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: VColors.tertiary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(VRadius.sm),
            border: Border.all(
              color: VColors.tertiary.withValues(
                alpha: 0.3 + (0.15 * _controller.value),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: VColors.tertiary.withValues(
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
              Icon(VIcons.sparkles, size: VIconSize.denseSm, color: VColors.tertiary),
              SizedBox(width: 4),
              Text(
                'SOVEREIGN DECREE',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.bold,
                  color: VColors.tertiary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  final List<String> imageUris;
  final bool edgeToEdge;

  const _ImageCarousel({
    required this.imageUris,
    this.edgeToEdge = false,
  });

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ClipRRect(
          borderRadius: widget.edgeToEdge
              ? BorderRadius.zero
              : BorderRadius.circular(VRadius.md),
          child: SizedBox(
            height: 250,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUris.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                return PostImage(
                  uri: widget.imageUris[index],
                  height: 250,
                  borderRadius: widget.edgeToEdge
                      ? BorderRadius.zero
                      : null,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: VSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_currentPage + 1}/${widget.imageUris.length}',
              style: TextStyle(fontSize: VFontSize.labelSm, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: VSpacing.sm),
            ...widget.imageUris.asMap().entries.map((entry) {
              return Container(
                width: entry.key == _currentPage ? 8 : 6,
                height: entry.key == _currentPage ? 8 : 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.key == _currentPage ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
