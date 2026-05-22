import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/paginated_result.dart';
import '../models/post.dart';
import '../models/repository_result.dart';
import '../models/sync_status.dart';
import '../services/mutation_outbox_service.dart';
import '../services/supabase.dart';
import '../services/world_service.dart';
import '../utils/validators.dart' as validators;

class PostRepository {
  const PostRepository();

  static const createPostMutation = 'post.create';
  static const editPostMutation = 'post.edit';
  static const deletePostMutation = 'post.delete';
  static const pinPostMutation = 'post.pin';
  static const reactPostMutation = 'post.react';
  static const commentPostMutation = 'post.comment';
  static const bookmarkPostMutation = 'post.bookmark';
  static const unbookmarkPostMutation = 'post.unbookmark';
  static const votePollMutation = 'post.poll.vote';

  /// Residents who share at least one of [worldIds] (for Nexus "Following" filter).
  Future<Set<String>> residentIdsInWorlds(
    List<String> worldIds, {
    String? excludeResidentId,
  }) async {
    if (!isSupabaseConfigured() || worldIds.isEmpty) return {};
    final client = getSupabase();
    final data = await client
        .from('world_members')
        .select('resident_id')
        .inFilter('world_id', worldIds);
    final ids = <String>{};
    for (final row in (data as List).cast<Map<String, dynamic>>()) {
      final id = row['resident_id'] as String?;
      if (id == null || id.isEmpty) continue;
      if (excludeResidentId != null && id == excludeResidentId) continue;
      ids.add(id);
    }
    return ids;
  }

  Future<PaginatedResult<Map<String, dynamic>>> loadPosts({
    String? worldId,
    String? cursor,
    int limit = 20,
  }) async {
    if (!isSupabaseConfigured()) {
      return const PaginatedResult(items: [], hasMore: false);
    }
    if (worldId != null && !WorldService.isRemoteWorldId(worldId)) {
      return const PaginatedResult(items: [], hasMore: false);
    }

    final client = getSupabase();
    var query = worldId != null
        ? client.from('posts').select().eq('world_id', worldId)
        : client.from('posts').select();

    if (cursor != null) {
      query = query.lt('created_at', cursor);
    }

    final data = await query
        .order('created_at', ascending: false)
        .limit(limit + 1);
    final list = (data as List).cast<Map<String, dynamic>>();
    final hasMore = list.length > limit;
    final items = hasMore ? list.sublist(0, limit) : list;
    return PaginatedResult(
      items: items,
      hasMore: hasMore,
      nextCursor: items.isNotEmpty ? items.last['created_at'] as String? : null,
    );
  }

  Future<RepositoryResult<Post>> createPost(Post post) async {
    return _runOrQueue<Post>(
      createPostMutation,
      _postPayload(post),
      () async {
        await getSupabase().from('posts').insert(_postRow(post));
        return post.copyWith(
          syncStatus: SyncStatus.synced,
          clearSyncError: true,
        );
      },
      data: post.copyWith(syncStatus: SyncStatus.pending),
    );
  }

  Future<RepositoryResult<void>> editPost({
    required String postId,
    required String content,
  }) {
    return _runOrQueue<void>(
      editPostMutation,
      {'postId': postId, 'content': content},
      () async {
        await getSupabase()
            .from('posts')
            .update({'content': content, 'is_edited': true})
            .eq('id', postId);
      },
    );
  }

  Future<RepositoryResult<void>> deletePost(String postId) {
    return _runOrQueue<void>(deletePostMutation, {'postId': postId}, () async {
      await getSupabase().from('posts').delete().eq('id', postId);
    });
  }

  Future<RepositoryResult<void>> setPinned({
    required String postId,
    required bool isPinned,
  }) {
    return _runOrQueue<void>(
      pinPostMutation,
      {'postId': postId, 'isPinned': isPinned},
      () async {
        await getSupabase()
            .from('posts')
            .update({'is_pinned': isPinned})
            .eq('id', postId);
      },
    );
  }

  Future<RepositoryResult<void>> addReaction({
    required String postId,
    required String emoji,
    required String residentId,
  }) {
    return _runOrQueue<void>(
      reactPostMutation,
      {'postId': postId, 'emoji': emoji, 'residentId': residentId},
      () async {
        final client = getSupabase();
        try {
          await client.rpc(
            'toggle_post_reaction_v2',
            params: {
              'p_post_id': postId,
              'p_emoji': emoji,
              'p_resident_id': residentId,
            },
          );
        } on PostgrestException {
          await client.rpc(
            'toggle_reaction',
            params: {
              'post_id': postId,
              'emoji': emoji,
              'resident_id': residentId,
            },
          );
        }
      },
    );
  }

  Future<RepositoryResult<void>> addComment({
    required String postId,
    required Comment comment,
  }) {
    return _runOrQueue<void>(
      commentPostMutation,
      {
        'postId': postId,
        'commentId': comment.id,
        'residentId': comment.residentId,
        'residentName': comment.residentName,
        'content': comment.content,
        'parentId': comment.parentId,
        'tierAtPosting': comment.tierAtPosting,
        'timestamp': comment.timestamp,
      },
      () async {
        final client = getSupabase();
        try {
          await client.rpc(
            'add_post_comment_v2',
            params: {
              'p_post_id': postId,
              'p_comment_id': comment.id,
              'p_resident_id': comment.residentId,
              'p_resident_name': comment.residentName,
              'p_content': comment.content,
              'p_parent_id': comment.parentId,
              'p_tier_at_posting': comment.tierAtPosting,
            },
          );
        } on PostgrestException {
          await client.rpc(
            'add_comment',
            params: {
              'post_id': postId,
              'resident_id': comment.residentId,
              'content': comment.content,
            },
          );
          await client.rpc(
            'increment_comment_count',
            params: {'post_id': postId},
          );
        }
      },
    );
  }

  Future<RepositoryResult<void>> setBookmark({
    required String postId,
    required String residentId,
    required bool bookmarked,
  }) {
    return _runOrQueue<void>(
      bookmarked ? bookmarkPostMutation : unbookmarkPostMutation,
      {'postId': postId, 'residentId': residentId},
      () async {
        final client = getSupabase();
        if (bookmarked) {
          await client.from('bookmarks').upsert({
            'post_id': postId,
            'user_id': residentId,
            'resident_id': residentId,
          });
        } else {
          await client
              .from('bookmarks')
              .delete()
              .eq('post_id', postId)
              .or('user_id.eq.$residentId,resident_id.eq.$residentId');
        }
      },
    );
  }

  Future<RepositoryResult<void>> votePoll({
    required Post post,
    required Poll poll,
    required String residentId,
  }) {
    return _runOrQueue<void>(
      votePollMutation,
      {'postId': post.id, 'residentId': residentId, 'poll': poll.toJson()},
      () async {
        await getSupabase()
            .from('posts')
            .update({'poll': poll.toJson()})
            .eq('id', post.id);
      },
    );
  }

  Future<void> replayOutbox() async {
    await MutationOutboxService.replay((mutation) async {
      switch (mutation.type) {
        case createPostMutation:
          await getSupabase().from('posts').upsert(mutation.payload);
          break;
        case editPostMutation:
          await editPost(
            postId: mutation.payload['postId'] as String,
            content: mutation.payload['content'] as String,
          );
          break;
        case deletePostMutation:
          await deletePost(mutation.payload['postId'] as String);
          break;
        case pinPostMutation:
          await setPinned(
            postId: mutation.payload['postId'] as String,
            isPinned: mutation.payload['isPinned'] as bool,
          );
          break;
        case reactPostMutation:
          await addReaction(
            postId: mutation.payload['postId'] as String,
            emoji: mutation.payload['emoji'] as String,
            residentId: mutation.payload['residentId'] as String,
          );
          break;
        case commentPostMutation:
          await addComment(
            postId: mutation.payload['postId'] as String,
            comment: Comment(
              id: mutation.payload['commentId'] as String,
              residentId: mutation.payload['residentId'] as String,
              residentName: mutation.payload['residentName'] as String? ?? '',
              content: mutation.payload['content'] as String,
              parentId: mutation.payload['parentId'] as String?,
              timestamp:
                  mutation.payload['timestamp'] as int? ??
                  DateTime.now().millisecondsSinceEpoch,
              tierAtPosting: mutation.payload['tierAtPosting'] as int? ?? 1,
            ),
          );
          break;
        case bookmarkPostMutation:
        case unbookmarkPostMutation:
          await setBookmark(
            postId: mutation.payload['postId'] as String,
            residentId: mutation.payload['residentId'] as String,
            bookmarked: mutation.type == bookmarkPostMutation,
          );
          break;
        case votePollMutation:
          final postId = mutation.payload['postId'] as String;
          await getSupabase()
              .from('posts')
              .update({'poll': mutation.payload['poll']})
              .eq('id', postId);
          break;
      }
    });
  }

  Future<RepositoryResult<T>> _runOrQueue<T>(
    String mutationType,
    Map<String, dynamic> payload,
    Future<T> Function() run, {
    T? data,
  }) async {
    if (!isSupabaseConfigured()) {
      await MutationOutboxService.enqueue(mutationType, payload);
      return RepositoryResult<T>.queued(data: data);
    }

    try {
      final result = await run();
      return RepositoryResult<T>.success(result);
    } catch (error, stackTrace) {
      await MutationOutboxService.enqueue(mutationType, payload);
      return RepositoryResult<T>.failure(error, stackTrace);
    }
  }

  static Map<String, dynamic> _postPayload(Post post) => _postRow(post);

  static Map<String, dynamic> _postRow(Post post) => {
    'id': post.id,
    'world_id': post.worldId,
    'resident_id': post.residentId,
    'resident_name': post.residentName,
    'author_id': post.residentId,
    'author_name': post.residentName,
    'author_avatar': post.residentAvatar,
    'resident_avatar': post.residentAvatar,
    'content': post.content,
    'image_url': post.imageUri,
    'media': post.allImageUris,
    'tier_at_posting': post.tierAtPosting.value,
    'is_announcement': post.isAnnouncement,
    'is_decree': post.isDecree,
    'is_pinned': post.isPinned,
    'is_edited': post.isEdited,
    'status': post.status,
    'reactions': post.reactions,
    'comments': post.comments
        .map(
          (comment) => {
            'id': comment.id,
            'residentId': comment.residentId,
            'residentName': comment.residentName,
            'content': comment.content,
            'timestamp': comment.timestamp,
            'parentId': comment.parentId,
            'tierAtPosting': comment.tierAtPosting,
          },
        )
        .toList(),
    'mentions': post.mentions,
    'hashtags': post.hashtags,
    'poll': post.poll?.toJson(),
    'scheduled_for': post.scheduledFor?.toIso8601String(),
  };

  static bool _isUuid(String value) => validators.isUuid(value);
}
