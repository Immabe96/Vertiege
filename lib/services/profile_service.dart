import '../models/resident.dart';
import 'supabase.dart';

class ProfileService {
  static Future<void> upsertProfile(Resident resident) async {
    if (!isSupabaseConfigured()) return;
    final client = await getSupabase();
    await client.from('profiles').upsert(_toProfileRow(resident));
  }

  static Future<Resident?> getProfile(String userId) async {
    if (!isSupabaseConfigured()) return null;
    final client = await getSupabase();
    final data = await client.from('profiles').select().eq('id', userId).single();
    if (data == null) return null;
    return _toResident(data);
  }

  static Future<List<Resident>> searchResidents(String query, {int limit = 20}) async {
    if (!isSupabaseConfigured()) return [];
    final client = await getSupabase();
    final data = await client
        .from('profiles')
        .select()
        .or('name.ilike.%$query%,profession.ilike.%$query%')
        .limit(limit);
    return (data as List).map((e) => _toResident(e)).toList();
  }

  static Future<List<Resident>> getTopResidents({int limit = 5}) async {
    if (!isSupabaseConfigured()) return [];
    final client = await getSupabase();
    final data = await client
        .from('profiles')
        .select()
        .order('tier', ascending: false)
        .order('streak_count', ascending: false)
        .limit(limit);
    return (data as List).map((e) => _toResident(e)).toList();
  }

  static Map<String, dynamic> _toProfileRow(Resident r) => {
        'id': r.id,
        'name': r.name,
        'bio': r.bio,
        'tier': r.tier.value,
        'avatar_url': r.avatarUrl,
        'profession': r.profession,
        'verified_roles': r.verifiedRoles,
        'decorations': r.decorations,
        'wealth_worlds_unlocked': r.wealthWorldsUnlocked,
        'cosmetics': {'badges': r.badges},
        'lastCheckIn': r.lastCheckIn,
        'streakCount': r.streakCount,
        'updated_at': DateTime.now().toIso8601String(),
      };

  static Resident _toResident(Map<String, dynamic> data) => Resident(
        id: data['id'] ?? '',
        name: data['name'] ?? 'Member',
        tier: ResidentTier.fromValue(data['tier'] ?? 1),
        bio: data['bio'] ?? '',
        avatarUrl: data['avatar_url'] ?? 'https://via.placeholder.com/150',
        profession: data['profession'],
        verifiedRoles: List<String>.from(data['verified_roles'] ?? []),
        decorations: List<String>.from(data['decorations'] ?? []),
        wealthWorldsUnlocked: List<String>.from(data['wealth_worlds_unlocked'] ?? []),
        badges: List<String>.from((data['cosmetics'] as Map?)?['badges'] ?? []),
        streakCount: data['streakCount'] ?? 0,
      );
}
