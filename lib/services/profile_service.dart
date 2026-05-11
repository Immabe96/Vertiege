import '../models/resident.dart';
import 'supabase.dart';

class ProfileService {
  static Future<void> upsertProfile(Resident resident) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('profiles').upsert(_toProfileRow(resident));
  }

  static Future<Resident?> getProfile(String userId) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client.from('profiles').select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return _toResident(data);
  }

  static Future<List<Resident>> searchResidents(String query, {int limit = 20}) async {
    if (!isSupabaseConfigured()) return [];
    // Strip characters that could interfere with PostgREST filter syntax
    final safe = query.replaceAll(RegExp(r'[%,.*()]'), '');
    if (safe.isEmpty) return [];
    final client = getSupabase();
    final data = await client
        .from('profiles')
        .select()
        .or('name.ilike.%$safe%,profession.ilike.%$safe%')
        .limit(limit);
    return (data as List).map((e) => _toResident(e)).toList();
  }

  static Future<List<Resident>> getTopResidents({int limit = 5}) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
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
        'last_check_in': r.lastCheckIn,
        'streak_count': r.streakCount,
        'streak_shields': r.streakShields,
        'following': r.following,
        'joined_world_ids': r.joinedWorldIds,
        'world_standings': r.worldStandings.map((k, v) => MapEntry(k, {'rep': v.rep})),
        'banned_world_ids': r.bannedWorldIds,
        'muted_until': r.mutedUntil,
        'last_seen_at': r.lastSeenAt,
        if (r.referredBy != null) 'referred_by': r.referredBy,
        if (r.title != null) 'title': r.title,
        'sovereign_coins': r.sovereignCoins,
        'onboarding_completed': r.onboardingCompleted,
        'gate_completed': r.gateCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      };

  static Resident _toResident(Map<String, dynamic> data) => Resident(
        id: data['id'] ?? '',
        name: data['name'] ?? 'Member',
        tier: ResidentTier.fromValue(data['tier'] ?? 1),
        bio: data['bio'] ?? '',
        avatarUrl: data['avatar_url'] ?? '',
        profession: data['profession'],
        verifiedRoles: List<String>.from(data['verified_roles'] ?? []),
        decorations: List<String>.from(data['decorations'] ?? []),
        wealthWorldsUnlocked: List<String>.from(data['wealth_worlds_unlocked'] ?? []),
        badges: List<String>.from((data['cosmetics'] as Map?)?['badges'] ?? []),
        lastCheckIn: data['last_check_in'] as String?,
        streakCount: (data['streak_count'] as int?) ?? 0,
        streakShields: (data['streak_shields'] as int?) ?? 0,
        following: List<String>.from(data['following'] ?? []),
        joinedWorldIds: List<String>.from(data['joined_world_ids'] ?? []),
        worldStandings: _parseWorldStandings(data['world_standings']),
        bannedWorldIds: List<String>.from(data['banned_world_ids'] ?? []),
        mutedUntil: (data['muted_until'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as int?) ?? 0)) ?? {},
        lastSeenAt: (data['last_seen_at'] as int?) ?? 0,
        referredBy: data['referred_by'] as String?,
        title: data['title'] as String?,
        sovereignCoins: (data['sovereign_coins'] as int?) ?? 100,
        onboardingCompleted: data['onboarding_completed'] ?? false,
        gateCompleted: data['gate_completed'] ?? false,
      );

  static Map<String, WorldStanding> _parseWorldStandings(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(
        k.toString(),
        WorldStanding(rep: (v is Map ? (v['rep'] as int?) ?? 0 : 0)),
      ));
    }
    return {};
  }
}
