import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/date_format.dart';
import '../profile/cosmetic_avatar.dart';
import '../core/empty_state.dart';
import '../core/tier_badge.dart';
import '../../ui/icons/v_icons.dart';

enum CommentSort { best, newest, oldest }

class CommentSheet extends StatefulWidget {
  final List<Comment> comments;
  final ValueChanged<String> onSubmit;
  final String? postAuthorId; // For OP badge

  const CommentSheet({
    super.key,
    required this.comments,
    required this.onSubmit,
    this.postAuthorId,
  });

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  late final TextEditingController _controller;
  CommentSort _sort = CommentSort.best;
  String? _replyToId; // F-01: Reply-to-comment
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
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

  int _getDepth(String commentId) {
    int depth = 0;
    String? current = commentId;
    final visited = <String>{};
    while (current != null) {
      if (depth > 20) return depth;
      if (visited.contains(current)) break;
      visited.add(current);
      final comment = widget.comments.firstWhere(
        (c) => c.id == current,
        orElse: () => widget.comments.first,
      );
      current = comment.parentId;
      if (current != null) depth++;
    }
    return depth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tree = _buildTree(widget.comments);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? VColors.glassBackgroundDark : VColors.glassBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VRadius.md),
            ),
            border: Border.all(color: isDark ? VColors.glassBorderDark : VColors.glassBorder),
          ),
          child: Column(
            children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
                child: Row(
                  children: [
                    Text(
                      'Comments',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    // F-13: Comment sort dropdown
                    _SortDropdown(
                      value: _sort,
                      onChanged: (sort) => setState(() => _sort = sort),
                    ),
                  ],
                ),
              ),
              const Divider(),
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
                            onReply: (id, name) {
                              setState(() {
                                _replyToId = id;
                                _replyToName = name;
                              });
                              FocusScope.of(context).requestFocus(
                                FocusNode(),
                              ); // Focus input
                            },
                          );
                        },
                      ),
              ),
              // F-01: Reply preview
              if (_replyToId != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.md,
                    vertical: VSpacing.xs,
                  ),
                  color: (isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer).withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: VIconSize.sm,
                        color: VColors.primary,
                      ),
                      const SizedBox(width: VSpacing.xs),
                      Expanded(
                        child: Text(
                          'Replying to $_replyToName',
                          style: TextStyle(
                            fontSize: VFontSize.labelSm,
                            color: VColors.primary,
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
                padding: const EdgeInsets.all(VSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: _replyToId != null
                              ? 'Reply to $_replyToName...'
                              : 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(VRadius.md),
                            ),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(VIcons.send),
                      onPressed: () {
                        if (_controller.text.trim().isNotEmpty) {
                          // If replying, prepend parent ID reference
                          final content = _replyToId != null
                              ? '@$_replyToName ${_controller.text.trim()}'
                              : _controller.text.trim();
                          widget.onSubmit(content);
                          _controller.clear();
                          setState(() {
                            _replyToId = null;
                            _replyToName = null;
                          });
                        }
                      },
                      tooltip: 'Send comment',
                      color: VColors.primary,
                    ),
                  ],
                ),
              ),
            ],
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
      icon: Icon(Icons.sort, size: VIconSize.md, color: VColors.outline),
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

  const _CommentTile({
    required this.comment,
    required this.depth,
    required this.isOp,
    required this.onReply,
    required this.allComments,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const maxDepth = 5;
    final effectiveDepth = widget.depth > maxDepth ? maxDepth : widget.depth;
    final indent = effectiveDepth * 12.0;
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
              margin: const EdgeInsets.only(left: 4, bottom: 4),
              color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
            ),
          if (isDeeplyNested)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: GestureDetector(
                onTap: () {
                  final parent = _findParent(widget.comment.parentId);
                  if (parent != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Replying to: ${parent.residentName}'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
                child: Text(
                  'show parent',
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: VColors.primary,
                    fontWeight: VFontWeight.semiBold,
                  ),
                ),
              ),
            ),
          if (_collapsed)
            GestureDetector(
              onTap: () => setState(() => _collapsed = false),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Show reply',
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: VColors.primary,
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
                      size: 28,
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
                                  color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                                ),
                              ),
                              const SizedBox(width: 4),
                              TierBadge(tier: widget.comment.tierAtPosting, size: 14),
                              if (widget.isOp)
                                Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: VColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(VRadius.xs),
                                  ),
                                  child: const Text(
                                    'OP',
                                    style: TextStyle(
                                      fontSize: VFontSize.labelSm,
                                      fontWeight: VFontWeight.bold,
                                      color: VColors.primary,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Text(
                                formatTimestamp(widget.comment.timestamp),
                                style: TextStyle(
                                  fontSize: VFontSize.labelSm,
                                  color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.comment.content,
                            style: TextStyle(
                              fontSize: VFontSize.bodyMd,
                              color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
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
                                    color: VColors.primary,
                                  ),
                                ),
                              ),
                              if (widget.depth > 0) ...[
                                const SizedBox(width: VSpacing.sm),
                                GestureDetector(
                                  onTap: () => setState(() => _collapsed = !_collapsed),
                                  child: Text(
                                    _collapsed ? 'Expand' : 'Collapse',
                                    style: TextStyle(
                                      fontSize: VFontSize.labelSm,
                                      color: isDark ? VColors.onSurfaceVariantDark : VColors.outline,
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
