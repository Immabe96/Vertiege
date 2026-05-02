import '../models/post.dart';
import 'supabase.dart';

class PostService {
  static Future<void> createPost({
    required String residentId,
    required String worldId,
    required String content,
    String? imageUrl,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('posts').insert({
      'resident_id': residentId,
      'world_id': worldId,
      'content': content,
      'image_url': imageUrl,
      'reactions': <String, List<String>>{},
      'comments': <Map<String, dynamic>>[],
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getPosts({String? worldId, int limit = 50}) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    var query = client.from('posts').select().order('created_at', ascending: false).limit(limit);
    if (worldId != null) query = query.eq('world_id', worldId);
    final data = await query;
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
