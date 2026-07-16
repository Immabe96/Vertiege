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
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/core/v_accessible.dart';
import '../widgets/feed/comment_sheet.dart';

/// Full-screen post comment thread — commune chat feel (DCX-092).
class PostCommentsScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostCommentsScreen({super.key, required this.postId});

  @override
  ConsumerState<PostCommentsScreen> createState() => _PostCommentsScreenState();
}

class _PostCommentsScreenState extends ConsumerState<PostCommentsScreen> {
  bool _resolving = false;
  bool _resolveFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePost());
  }

  Future<void> _ensurePost() async {
    final posts = ref.read(postProvider).posts;
    if (posts.any((p) => p.id == widget.postId)) return;
    setState(() {
      _resolving = true;
      _resolveFailed = false;
    });
    final ok =
        await ref.read(postProvider.notifier).ensurePostVisible(widget.postId);
    if (!mounted) return;
    setState(() {
      _resolving = false;
      _resolveFailed = !ok;
    });
  }

  Post? _findPost(List<Post> posts) {
    for (final candidate in posts) {
      if (candidate.id == widget.postId) return candidate;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(postProvider).posts;
    final post = _findPost(posts);

    if (post == null) {
      return ColoredBox(
        color: VCommuneColors.surfacePrimary,
        child: VScaffold(
          header: VNestedHeader(
            prefixes: [
              VAccessibleHeaderAction(
                label: 'Back',
                icon: const Icon(VIcons.chevronLeft),
                onPress: () {
                  if (context.canPop()) context.pop();
                },
              ),
            ],
            title: const Text('Comments'),
          ),
          child: _resolving
              ? const ScreenLoading.list()
              : AppEmptyState(
                  icon: Icons.chat_bubble_outline,
                  title: 'Post not found',
                  description: _resolveFailed
                      ? 'Could not load this thread. Check your connection.'
                      : 'This post is no longer available.',
                  actionLabel: 'Retry',
                  onAction: _ensurePost,
                ),
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
              icon: const Icon(VIcons.chevronLeft),
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
          comments: activePost.comments,
          postAuthorId: activePost.residentId,
          postId: activePost.id,
          worldId: activePost.worldId,
          embedded: true,
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
