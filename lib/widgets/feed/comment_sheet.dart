import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/post.dart';
import '../../services/moderation_service.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../core/tab_aware_sheet.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/date_format.dart';
import '../profile/cosmetic_avatar.dart';
import '../core/empty_state.dart';
import '../core/tier_badge.dart';
import '../../ui/icons/v_icons.dart';
import '../../widgets/core/v_feedback.dart';
import '../report_sheet.dart';

enum CommentSort { best, newest, oldest }

/// Full-screen comment thread (DCX-092).
void openPostComments(
  BuildContext context, {
  required String postId,
}) {
  context.push('/post/$postId/comments');
}

/// Opens comments above tab-shell chrome (legacy sheet).
Future<void> showPostCommentSheet({
  required BuildContext context,
  required CommentSheet sheet,
}) {
  return showTabAwareModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => sheet,
  );
}

class CommentSheet extends StatefulWidget {
  final List<Comment> comments;
  final ValueChanged<String> onSubmit;
  final String? postAuthorId;
  final String? postId;
  final String? worldId;
  final bool embedded;

  const CommentSheet({
    super.key,
    required this.comments,
    required this.onSubmit,
    this.postAuthorId,
    this.postId,
    this.worldId,
    this.embedded = false,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  late final TextEditingController _controller;
  ScrollController? _listController;
  CommentSort _sort = CommentSort.best;
  String? _replyToId;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    if (widget.embedded) {
      _listController = ScrollController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _listController?.dispose();
    super.dispose();
  }

  // F-12: Build nested comment tree from flat list
  List<Comment> _buildTree(List<Comment> comments) {
    final idToComment = <String, Comment>{};
    final children = <String, List<Comment>>{};
    final roots = <Comment>[];

    for (final c in comments) {
      idToComment[c.id] = c;
      if (c.parentId == null) {
        roots.add(c);
      } else {
        children.putIfAbsent(c.parentId!, () => []).add(c);
      }
    }

    // Sort children recursively
    List<Comment> sortList(List<Comment> list) {
      final sorted = List<Comment>.from(list);
      switch (_sort) {
        case CommentSort.newest:
          sorted.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          break;
        case CommentSort.oldest:
          sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          break;
        case CommentSort.best:
          // Simple: more replies = higher
          sorted.sort((a, b) {
            final aCount = children[a.id]?.length ?? 0;
            final bCount = children[b.id]?.length ?? 0;
            return bCount.compareTo(aCount);
          });
          break;
      }
      return sorted;
    }

    // Attach children to roots
    final result = <Comment>[];
    for (final root in sortList(roots)) {
      result.add(root);
      _attachChildren(root, children, sortList, result);
    }
    return result;
  }

  void _attachChildren(
    Comment parent,
    Map<String, List<Comment>> children,
    List<Comment> Function(List<Comment>) sortList,
    List<Comment> result,
  ) {
    final kids = children[parent.id];
    if (kids == null || kids.isEmpty) return;
    for (final child in sortList(kids)) {
      result.add(child);
      _attachChildren(child, children, sortList, result);
    }
  }

  void _submitComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final content = _replyToId != null
        ? '@$_replyToName $text'
        : text;
    widget.onSubmit(content);
    _controller.clear();
    setState(() {
      _replyToId = null;
      _replyToName = null;
    });
  }

  int _getDepth(String commentId) {
    int depth = 0;
    String? current = commentId;
    final visited = <String>{};
    while (current != null) {
      if (depth > 20) return depth;
      if (visited.contains(current)) break;
      visited.add(current);
      final idx = widget.comments.indexWhere((c) => c.id == current);
      if (idx == -1) break;
      final comment = widget.comments[idx];
      current = comment.parentId;
      if (current != null) depth++;
    }
    return depth;
  }

  Widget _buildThreadBody({
    required ThemeData theme,
    required List<Comment> tree,
    required ScrollController scrollController,
  }) {
    return Column(
      children: [
        if (!widget.embedded) ...[
          const SizedBox(height: VSpacing.sm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(VRadius.sm),
            ),
          ),
          const SizedBox(height: VSpacing.sm),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
          child: Row(
            children: [
              Text(
                'Comments',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: widget.embedded
                      ? VCommuneColors.headerPrimary
                      : null,
                ),
              ),
              const Spacer(),
              _SortDropdown(
                value: _sort,
                onChanged: (sort) => setState(() => _sort = sort),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: widget.embedded
              ? VCommuneColors.dividerSubtle
              : null,
        ),
        Expanded(
          child: tree.isEmpty
              ? const AppEmptyState(
                  title: 'No comments yet',
                  description: 'Be the first to share your thoughts.',
                  icon: Icons.chat_bubble_outline,
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: tree.length,
                  itemBuilder: (context, index) {
                    final comment = tree[index];
                    final depth = _getDepth(comment.id);
                    return _CommentTile(
                      comment: comment,
                      depth: depth,
                      isOp: widget.postAuthorId != null &&
                          comment.residentId == widget.postAuthorId,
                      allComments: widget.comments,
                      postId: widget.postId,
                      worldId: widget.worldId,
                      onReply: (id, name) {
                        setState(() {
                          _replyToId = id;
                          _replyToName = name;
                        });
                      },
                    );
                  },
                ),
        ),
        if (_replyToId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.md,
                    vertical: VSpacing.xs,
                  ),
                  color: VColors.surfaceContainerDark.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: VIconSize.sm,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: VSpacing.xs),
                      Expanded(
                        child: Text(
                          'Replying to $_replyToName',
                          style: TextStyle(
                            fontSize: VFontSize.labelSm,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: VFontWeight.semiBold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(VIcons.x, size: VIconSize.sm),
                        onPressed: () => setState(() {
                          _replyToId = null;
                          _replyToName = null;
                        }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  VSpacing.sm,
                  VSpacing.sm,
                  VSpacing.sm,
                  MediaQuery.viewInsetsOf(context).bottom +
                      MediaQuery.paddingOf(context).bottom +
                      VSpacing.xs,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                        decoration: InputDecoration(
                          hintText: _replyToId != null
                              ? 'Reply to $_replyToName...'
                              : 'Add a comment...',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(VRadius.md),
                            ),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: VSpacing.xs),
                    IconButton(
                      icon: const Icon(VIcons.send),
                      onPressed: _submitComment,
                      tooltip: 'Send comment',
                      color: Theme.of(context).colorScheme.primary,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(
                          VTouchTarget.iconButton,
                          VTouchTarget.iconButton,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tree = _buildTree(widget.comments);

    if (widget.embedded) {
      return _buildThreadBody(
        theme: theme,
        tree: tree,
        scrollController: _listController!,
      );
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VRadius.md),
            ),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: _buildThreadBody(
            theme: theme,
            tree: tree,
            scrollController: scrollController,
          ),
        );
      },
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final CommentSort value;
  final ValueChanged<CommentSort> onChanged;

  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<CommentSort>(
      icon: const Icon(Icons.sort, size: VIconSize.md, color: VColors.outline),
      tooltip: 'Sort comments',
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: CommentSort.best,
          child: Row(
            children: [
              Icon(VIcons.flame, size: VIconSize.sm),
              SizedBox(width: VSpacing.sm),
              Text('Best'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: CommentSort.newest,
          child: Row(
            children: [
              Icon(Icons.new_releases, size: VIconSize.sm),
              SizedBox(width: VSpacing.sm),
              Text('Newest'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: CommentSort.oldest,
          child: Row(
            children: [
              Icon(Icons.history, size: VIconSize.sm),
              SizedBox(width: VSpacing.sm),
              Text('Oldest'),
            ],
          ),
        ),
      ],
      onSelected: onChanged,
    );
  }
}

class _CommentTile extends StatefulWidget {
  final Comment comment;
  final int depth;
  final bool isOp;
  final void Function(String id, String name) onReply;
  final List<Comment> allComments;
  final String? postId;
  final String? worldId;

  const _CommentTile({
    required this.comment,
    required this.depth,
    required this.isOp,
    required this.onReply,
    required this.allComments,
    this.postId,
    this.worldId,
  });

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _collapsed = false;

  Comment? _findParent(String? parentId) {
    if (parentId == null) return null;
    try {
      return widget.allComments.firstWhere((c) => c.id == parentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const maxDepth = 5;
    final effectiveDepth = widget.depth > maxDepth ? maxDepth : widget.depth;
    final indent = effectiveDepth * VSpacing.md;
    final isDeeplyNested = widget.depth > 2;

    return Padding(
      padding: EdgeInsets.only(left: indent, right: VSpacing.md, top: VSpacing.xs, bottom: VSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.depth > 0)
            Container(
              width: 2,
              height: 20,
              margin: const EdgeInsets.only(left: VSpacing.xs, bottom: VSpacing.xs),
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          if (isDeeplyNested)
            Padding(
              padding: const EdgeInsets.only(left: VSpacing.xs, bottom: VSpacing.xs),
              child: GestureDetector(
                onTap: () {
                  final parent = _findParent(widget.comment.parentId);
                  if (parent != null) {
                    VFeedback.showMessage(context, 'Replying to: ${parent.residentName}');
                  }
                },
                child: Text(
                  'show parent',
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: VFontWeight.semiBold,
                  ),
                ),
              ),
            ),
            if (_collapsed)
              GestureDetector(
                onTap: () => setState(() => _collapsed = false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: VSpacing.xs),
                child: Text(
                  'Show reply',
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: VFontWeight.semiBold,
                  ),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CosmeticAvatar(
                      size: VIconSize.lg,
                      seed: widget.comment.residentName,
                    ),
                    const SizedBox(width: VSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                               widget.comment.residentName,
                               style: TextStyle(
                                 fontSize: VFontSize.labelSm,
                                 fontWeight: VFontWeight.semiBold,
                                 color: Theme.of(context).colorScheme.onSurface,
                               ),
                              ),
                              const SizedBox(width: VSpacing.xs),
                               TierBadge(tier: widget.comment.tierAtPosting, size: VIconSize.denseSm),
                              if (widget.isOp)
                                Container(
                                  margin: const EdgeInsets.only(left: VSpacing.xs),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: VSpacing.xs,
                                    vertical: VSpacing.xxs,
                                  ),
                                   decoration: BoxDecoration(
                                     color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                     borderRadius: BorderRadius.circular(VRadius.xs),
                                   ),
                                   child: Text(
                                     'OP',
                                     style: TextStyle(
                                       fontSize: VFontSize.labelSm,
                                       fontWeight: VFontWeight.bold,
                                       color: Theme.of(context).colorScheme.primary,
                                     ),
                                   ),
                                ),
                              const Spacer(),
                              Text(
                                 formatTimestamp(widget.comment.timestamp),
                                 style: TextStyle(
                                   fontSize: VFontSize.labelSm,
                                   color: Theme.of(context).colorScheme.onSurfaceVariant,
                                 ),
                              ),
                            ],
                          ),
                          const SizedBox(height: VSpacing.xxs),
                          Text(
                           widget.comment.content,
                           style: TextStyle(
                             fontSize: VFontSize.bodyMd,
                             color: Theme.of(context).colorScheme.onSurface,
                             height: VLineHeight.body,
                           ),
                          ),
                          const SizedBox(height: VSpacing.xs),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => widget.onReply(widget.comment.id, widget.comment.residentName),
                                child: Text(
                                   'Reply',
                                   style: TextStyle(
                                     fontSize: VFontSize.labelSm,
                                     fontWeight: VFontWeight.semiBold,
                                     color: Theme.of(context).colorScheme.primary,
                                   ),
                                 ),
                              ),
                              if (widget.postId != null) ...[
                                const SizedBox(width: VSpacing.md),
                                GestureDetector(
                                  onTap: () {
                                    final container = ProviderScope.containerOf(
                                      context,
                                    );
                                    final me = container
                                        .read(residentProvider)
                                        .resident;
                                    if (me == null) return;
                                    ReportSheet.show(
                                      context,
                                      targetLabel: 'comment',
                                      onSubmit: (reason, details) {
                                        Navigator.pop(context);
                                        ModerationService.submitReport(
                                          worldId: widget.worldId,
                                          postId: widget.postId,
                                          reporterId: me.id,
                                          reason: reason.name,
                                          details: [
                                            'comment_id:${widget.comment.id}',
                                            if (details != null &&
                                                details.isNotEmpty)
                                              details,
                                          ].join('\n'),
                                        );
                                        VFeedback.showMessage(
                                          context,
                                          'Report submitted. Thank you.',
                                        );
                                      },
                                    );
                                  },
                                  child: Text(
                                    'Report',
                                    style: TextStyle(
                                      fontSize: VFontSize.labelSm,
                                      fontWeight: VFontWeight.semiBold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                              if (widget.depth > 0) ...[
                                const SizedBox(width: VSpacing.sm),
                                GestureDetector(
                                  onTap: () => setState(() => _collapsed = !_collapsed),
                                  child: Text(
                                     _collapsed ? 'Expand' : 'Collapse',
                                     style: TextStyle(
                                       fontSize: VFontSize.labelSm,
                                       color: Theme.of(context).colorScheme.onSurfaceVariant,
                                     ),
                                   ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
