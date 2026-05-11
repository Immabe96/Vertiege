import 'moderation_filter.dart';
import 'supabase.dart';

class PostService {
  static Future<String?> createPost({
    required String residentId,
    required String residentName,
    required String worldId,
    required String content,
    String? imageUrl,
    String residentAvatar = '',
    int tierAtPosting = 1,
    bool isAnnouncement = false,
  }) async {
    if (!isSupabaseConfigured()) return 'Service unavailable';

    final moderationResult = ModerationFilter.checkContent(content);
    if (moderationResult != null) return moderationResult;

    if (!_isUuid(worldId) || !_isUuid(residentId)) return null;

    final client = getSupabase();
    await client.from('posts').insert({
      'world_id': worldId,
      'author_id': residentId,
      'author_name': residentName,
      'author_avatar': residentAvatar,
      'content': content,
      'media': imageUrl == null ? <String>[] : <String>[imageUrl],
      'is_announcement': isAnnouncement,
      'is_decree': false,
      'is_pinned': false,
      'reactions': <String, dynamic>{},
      'comment_count': 0,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    return null;
  }

  static Future<List<Map<String, dynamic>>> getPosts({
    String? worldId,
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    if (worldId != null && !_isUuid(worldId)) return [];

    final client = getSupabase();
    final data = worldId != null
        ? await client
              .from('posts')
              .select()
              .eq('world_id', worldId)
              .order('created_at', ascending: false)
              .limit(limit)
        : await client
              .from('posts')
              .select()
              .order('created_at', ascending: false)
              .limit(limit);
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
    final row = await client
        .from('posts')
        .select('reactions')
        .eq('id', postId)
        .maybeSingle();
    final reactions = Map<String, dynamic>.from(row?['reactions'] ?? {});
    reactions[emoji] = ((reactions[emoji] as int?) ?? 0) + 1;
    await client
        .from('posts')
        .update({'reactions': reactions})
        .eq('id', postId);
  }

  static Future<void> addComment(
    String postId,
    String residentId,
    String content,
  ) async {
    if (!isSupabaseConfigured()) return;
    if (!_isUuid(postId)) return;

    final client = getSupabase();
    final row = await client
        .from('posts')
        .select('comment_count')
        .eq('id', postId)
        .maybeSingle();
    final count = (row?['comment_count'] as int?) ?? 0;
    await client
        .from('posts')
        .update({'comment_count': count + 1})
        .eq('id', postId);
  }

  static bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
