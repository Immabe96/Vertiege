import '../models/rank.dart';
import '../utils/id_generator.dart';
import 'supabase.dart';

class RankService {
  static Future<void> createRank({
    required String worldId,
    required String name,
    String colorHex = '#CFBCFF',
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    final maxPos = await client
        .from('world_ranks')
        .select('position')
        .eq('world_id', worldId)
        .order('position', ascending: false)
        .limit(1)
        .maybeSingle();
    final nextPos = (maxPos?['position'] ?? -1) + 1;
    await client.from('world_ranks').insert({
      'id': generateId(),
      'world_id': worldId,
      'name': name,
      'color': colorHex,
      'position': nextPos,
    });
  }

  static Future<void> updateRank({
    required String rankId,
    String? name,
    String? colorHex,
    bool? isHoisted,
    bool? isMentionable,
    Map<String, bool>? edicts,
  }) async {
    if (!isSupabaseConfigured()) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (colorHex != null) updates['color'] = colorHex;
    if (isHoisted != null) updates['is_hoisted'] = isHoisted;
    if (isMentionable != null) updates['is_mentionable'] = isMentionable;
    if (edicts != null) updates['edicts'] = edicts;
    if (updates.isNotEmpty) {
      await getSupabase().from('world_ranks').update(updates).eq('id', rankId);
    }
  }

  static Future<void> deleteRank(String rankId) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase().from('world_ranks').delete().eq('id', rankId);
  }

  static Future<List<Rank>> fetchWorldRanks(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final data = await getSupabase()
        .from('world_ranks')
        .select()
        .eq('world_id', worldId)
        .order('position');
    return (data as List)
        .map((e) => Rank.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  // ── Resident rank assignment ────────────────────────────

  static Future<void> assignRank({
    required String residentId,
    required String rankId,
  }) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase().from('resident_ranks').upsert({
      'resident_id': residentId,
      'rank_id': rankId,
    });
  }

  static Future<void> removeRank({
    required String residentId,
    required String rankId,
  }) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase()
        .from('resident_ranks')
        .delete()
        .eq('resident_id', residentId)
        .eq('rank_id', rankId);
  }

  static Future<List<String>> fetchResidentRankIds(String residentId) async {
    if (!isSupabaseConfigured()) return [];
    final data = await getSupabase()
        .from('resident_ranks')
        .select('rank_id')
        .eq('resident_id', residentId);
    return (data as List).map((e) => e['rank_id'] as String).toList();
  }
}
