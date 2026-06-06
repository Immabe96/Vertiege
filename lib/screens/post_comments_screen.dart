import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';

import '../models/post.dart';
import '../state/post_provider.dart';
import '../state/resident_provider.dart';
import '../theme/v_commune_chat_theme.dart';
import '../theme/v_commune_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/v_accessible.dart';
import '../widgets/feed/comment_sheet.dart';

/// Full-screen post comment thread — commune chat feel (DCX-092).
class PostCommentsScreen extends ConsumerWidget {
  final String postId;

  const PostCommentsScreen({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(postProvider).posts;
    Post? post;
    for (final candidate in posts) {
      if (candidate.id == postId) {
        post = candidate;
        break;
      }
    }

    if (post == null) {
      return ColoredBox(
        color: VCommuneColors.surfacePrimary,
        child: VScaffold(
          header: VNestedHeader(
            prefixes: [
              VAccessibleHeaderAction(
                label: 'Back',
                icon: Icon(VIcons.chevronLeft),
                onPress: () {
                  if (context.canPop()) context.pop();
                },
              ),
            ],
            title: const Text('Comments'),
          ),
          child: const Center(child: Text('Post not found')),
        ),
      );
    }

    final activePost = post;
    return ColoredBox(
      color: VCommuneChatTheme.backgroundColor,
      child: VScaffold(
        header: VNestedHeader(
          prefixes: [
            VAccessibleHeaderAction(
              label: 'Back to feed',
              icon: Icon(VIcons.chevronLeft),
              onPress: () {
                if (context.canPop()) context.pop();
              },
            ),
          ],
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thread'),
              Text(
                activePost.residentName,
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  color: VCommuneChatTheme.timestampMuted,
                ),
              ),
            ],
          ),
        ),
        child: CommentSheet(
          embedded: true,
          comments: activePost.comments,
          postAuthorId: activePost.residentId,
          onSubmit: (content) {
            final resident = ref.read(residentProvider).resident;
            if (resident == null) return;
            final comment = Comment(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              residentId: resident.id,
              residentName: resident.name,
              content: content,
              timestamp: DateTime.now().millisecondsSinceEpoch,
              tierAtPosting: resident.tier.value,
            );
            ref.read(postProvider.notifier).addComment(activePost.id, comment);
          },
        ),
      ),
    );
  }
}
