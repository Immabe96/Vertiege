import '../models/announcement.dart';
import 'supabase.dart';

class AnnouncementService {
  static Future<List<WorldAnnouncement>> getAnnouncements(
    String worldId, {
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('world_announcements')
        .select()
        .eq('world_id', worldId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => WorldAnnouncement.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<WorldAnnouncement?> createAnnouncement({
    required String worldId,
    required String title,
    required String content,
    String? imageUrl,
    String priority = AnnouncementPriority.normal,
    bool isPinned = false,
    DateTime? expiresAt,
  }) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final result = await client
        .from('world_announcements')
        .insert({
          'world_id': worldId,
          'author_id': userId,
          'title': title,
          'content': content,
          if (imageUrl != null) 'image_url': imageUrl,
          'priority': priority,
          'is_pinned': isPinned,
          if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
        })
        .select()
        .single();

    return WorldAnnouncement.fromSupabase(result);
  }

  static Future<bool> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    String? imageUrl,
    String? priority,
    bool? isPinned,
    DateTime? expiresAt,
  }) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client
        .from('world_announcements')
        .update({
          'title': title,
          'content': content,
          if (imageUrl != null) 'image_url': imageUrl,
          if (priority != null) 'priority': priority,
          if (isPinned != null) 'is_pinned': isPinned,
          if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    return true;
  }

  static Future<bool> deleteAnnouncement(String id) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client.from('world_announcements').delete().eq('id', id);
    return true;
  }
}
