import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../utils/date_format.dart';

class CommentSheet extends StatefulWidget {
  final List<Comment> comments;
  final ValueChanged<String> onSubmit;

  const CommentSheet({super.key, required this.comments, required this.onSubmit});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  late final TextEditingController _controller;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(RadiusTokens.cardFeatured)),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            children: [
              const SizedBox(height: Spacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text('Comments', style: theme.textTheme.titleMedium),
              const Divider(),
              Expanded(
                child: widget.comments.isEmpty
                    ? Center(
                        child: Text('No comments yet', style: theme.textTheme.bodyMedium))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: widget.comments.length,
                        itemBuilder: (context, index) {
                          final comment = widget.comments[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(comment.residentName[0])),
                            title: Text(comment.residentName, style: theme.textTheme.labelMedium),
                            subtitle: Text(comment.content),
                            trailing: Text(formatTimestamp(comment.timestamp),
                                style: theme.textTheme.labelSmall),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(RadiusTokens.input)),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_controller.text.trim().isNotEmpty) {
                          widget.onSubmit(_controller.text.trim());
                          _controller.clear();
                        }
                      },
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
