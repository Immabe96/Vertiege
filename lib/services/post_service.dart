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

    final client = getSupabase();
    await client.from('posts').insert({
      'resident_id': residentId,
      'resident_name': residentName,
      'resident_avatar': residentAvatar,
      'world_id': worldId,
      'content': content,
      'image_url': imageUrl,
      'tier_at_posting': tierAtPosting,
      'is_announcement': isAnnouncement,
      'is_pinned': false,
      'is_edited': false,
      'reactions': <String, dynamic>{},
      'comments': <Map<String, dynamic>>[],
      'created_at': DateTime.now().toIso8601String(),
    });
    return null;
  }

  static Future<List<Map<String, dynamic>>> getPosts({String? worldId, int limit = 50}) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = worldId != null
        ? await client.from('posts').select().eq('world_id', worldId).order('created_at', ascending: false).limit(limit)
        : await client.from('posts').select().order('created_at', ascending: false).limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<void> addReaction(String postId, String emoji, String residentId) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.rpc('toggle_reaction', params: {
      'post_id': postId,
      'emoji': emoji,
      'resident_id': residentId,
    });
  }

  static Future<void> addComment(String postId, String residentId, String content) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.rpc('add_comment', params: {
      'post_id': postId,
      'resident_id': residentId,
      'content': content,
    });
  }
}
