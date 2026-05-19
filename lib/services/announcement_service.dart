import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/id_generator.dart';
import 'supabase.dart';
import 'crash_reporter.dart';

class AnnouncementService {
  static Future<List<Map<String, dynamic>>> getAnnouncements(
    String worldId,
  ) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('world_announcements')
        .select()
        .eq('world_id', worldId)
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<String?> createAnnouncement({
    required String worldId,
    required String authorId,
    required String authorName,
    required String title,
    required String content,
    String? imageUrl,
    String priority = 'normal',
    bool isPinned = false,
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to create announcements.');
    }
    final client = getSupabase();
    final id = generateId();
    await client.from('world_announcements').insert({
      'id': id,
      'world_id': worldId,
      'author_id': authorId,
      'author_name': authorName,
      'title': title,
      'content': content,
      if (imageUrl != null) 'image_url': imageUrl,
      'priority': priority,
      'is_pinned': isPinned,
    });
    return id;
  }

  static Future<bool> updateAnnouncement({
    required String announcementId,
    String? title,
    String? content,
    String? imageUrl,
    String? priority,
    bool? isPinned,
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to update announcements.');
    }
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (content != null) updates['content'] = content;
    if (imageUrl != null) updates['image_url'] = imageUrl;
    if (priority != null) updates['priority'] = priority;
    if (isPinned != null) updates['is_pinned'] = isPinned;
    if (updates.isEmpty) return true;
    final client = getSupabase();
    await client
        .from('world_announcements')
        .update(updates)
        .eq('id', announcementId);
    return true;
  }

  static Future<bool> deleteAnnouncement(String announcementId) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to delete announcements.');
    }
    final client = getSupabase();
    await client
        .from('world_announcements')
        .delete()
        .eq('id', announcementId);
    return true;
  }
}
