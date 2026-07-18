import '../models/paginated_result.dart';
import '../utils/id_generator.dart';
import '../utils/validators.dart' as validators;
import 'moderation_filter.dart';
import 'supabase.dart';

class PostService {
  /// Columns needed for feed/list rendering (avoid select *).
  static const feedSelectColumns =
      'id, world_id, resident_id, resident_name, author_id, author_name, '
      'author_display_title, author_avatar, resident_avatar, content, '
      'image_url, media, created_at, tier_at_posting, reactions, '
      'is_announcement, is_pinned, is_edited, is_decree, status, '
      'repost_of, mentions, hashtags, poll, event_title, event_starts_at, '
      'event_rsvp_ids, scheduled_for, awards, comment_count';

  static Future<String?> createPost({
    required String residentId,
    required String residentName,
    String? authorDisplayTitle,
    required String worldId,
    required String content,
    String? imageUrl,
    String residentAvatar = '',
    int tierAtPosting = 1,
    bool isAnnouncement = false,
  }) async {
    if (!isSupabaseConfigured()) return 'Service unavailable';

    final moderationResult = await ModerationFilter.checkContentAsync(content);
    if (moderationResult != null) return moderationResult;

    if (!_isUuid(worldId) || !_isUuid(residentId)) return null;

    final client = getSupabase();
    await client.from('posts').insert({
      'id': generateId(),
      'world_id': worldId,
      'resident_id': residentId,
      'resident_name': residentName,
      'author_id': residentId,
      'author_name': residentName,
      if (authorDisplayTitle != null && authorDisplayTitle.isNotEmpty)
        'author_display_title': authorDisplayTitle,
      'author_avatar': residentAvatar,
      'content': content,
      'media': imageUrl == null ? <String>[] : <String>[imageUrl],
      'is_announcement': isAnnouncement,
      'is_decree': false,
      'is_pinned': false,
      'reactions': <String, dynamic>{},
      'comment_count': 0,
    });
    return null;
  }

  static Future<PaginatedResult<Map<String, dynamic>>> getPosts({
    String? worldId,
    String? cursor,
    int limit = 20,
  }) async {
    if (!isSupabaseConfigured()) {
      return const PaginatedResult(items: [], hasMore: false);
    }
    if (worldId != null && !_isUuid(worldId)) {
      return const PaginatedResult(items: [], hasMore: false);
    }

    final client = getSupabase();
    var query = worldId != null
        ? client
            .from('posts')
            .select(feedSelectColumns)
            .eq('world_id', worldId)
        : client.from('posts').select(feedSelectColumns);

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

  static Future<List<Map<String, dynamic>>> getFollowingPosts(
    String residentId,
    List<String> followingIds,
  ) async {
    if (!isSupabaseConfigured()) return [];
    if (followingIds.isEmpty) return [];

    final client = getSupabase();
    final data = await client
        .from('posts')
        .select(feedSelectColumns)
        .inFilter('resident_id', followingIds)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<void> addReaction(
    String postId,
    String emoji,
    String residentId,
  ) async {
    if (!isSupabaseConfigured()) return;
    if (!_isUuid(postId)) return;

    final client = getSupabase();
    await client.rpc('toggle_reaction', params: {
      'post_id': postId,
      'emoji': emoji,
      'resident_id': residentId,
    });
  }

  static Future<void> addComment(
    String postId,
    String residentId,
    String content,
  ) async {
    if (!isSupabaseConfigured()) return;
    if (!_isUuid(postId)) return;

    final client = getSupabase();
    await client.rpc('add_comment', params: {
      'post_id': postId,
      'resident_id': residentId,
      'content': content,
    });
    try {
      await client.rpc('increment_comment_count', params: {'post_id': postId});
    } catch (_) {}
  }

  static bool _isUuid(String value) => validators.isUuid(value);
}
