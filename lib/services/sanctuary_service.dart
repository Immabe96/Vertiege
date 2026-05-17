import '../models/sanctuary.dart';
import 'supabase.dart';

class SanctuaryService {
  static Future<List<SanctuaryMood>> getMoods(
    String worldId,
    String residentId, {
    int limit = 30,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('sanctuary_moods')
        .select()
        .eq('world_id', worldId)
        .eq('resident_id', residentId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => SanctuaryMood.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<SanctuaryMood?> logMood({
    required String worldId,
    required int moodLevel,
    String? moodNote,
  }) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final result = await client
        .from('sanctuary_moods')
        .insert({
          'world_id': worldId,
          'resident_id': userId,
          'mood_level': moodLevel,
          if (moodNote != null) 'mood_note': moodNote,
        })
        .select()
        .single();

    return SanctuaryMood.fromSupabase(result);
  }

  static Future<List<SanctuaryGratitude>> getGratitudePosts(
    String worldId, {
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('sanctuary_gratitude')
        .select()
        .eq('world_id', worldId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => SanctuaryGratitude.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<SanctuaryGratitude?> postGratitude({
    required String worldId,
    required String content,
    bool isAnonymous = false,
  }) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final result = await client
        .from('sanctuary_gratitude')
        .insert({
          'world_id': worldId,
          'author_id': userId,
          'content': content,
          'is_anonymous': isAnonymous,
        })
        .select()
        .single();

    return SanctuaryGratitude.fromSupabase(result);
  }

  static Future<bool> deleteGratitude(String id) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client.from('sanctuary_gratitude').delete().eq('id', id);
    return true;
  }
}
