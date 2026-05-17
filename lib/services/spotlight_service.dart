import '../services/supabase.dart';
import '../services/profile_service.dart';
import '../models/resident.dart';

class SpotlightEntry {
  final String residentId;
  final String worldId;
  final DateTime spotlightedAt;

  const SpotlightEntry({
    required this.residentId,
    required this.worldId,
    required this.spotlightedAt,
  });

  Map<String, dynamic> toJson() => {
    'resident_id': residentId,
    'world_id': worldId,
    'spotlighted_at': spotlightedAt.toIso8601String(),
  };

  static SpotlightEntry fromSupabase(Map<String, dynamic> data) => SpotlightEntry(
    residentId: data['resident_id'] as String,
    worldId: data['world_id'] as String,
    spotlightedAt: DateTime.parse(data['spotlighted_at'] as String),
  );
}

class SpotlightService {
  static final Map<String, _SpotlightCache> _cache = {};

  static Future<Resident?> getSpotlightResident(String worldId) async {
    final today = DateTime.now();
    final todayKey = '${worldId}_${today.year}_${today.month}_${today.day}';

    if (_cache.containsKey(todayKey)) {
      final cached = _cache[todayKey]!;
      if (cached.residentId != null) {
        return _fetchResident(cached.residentId!);
      }
      return null;
    }

    try {
      final alreadySpotlighted = await _getRecentlySpotlighted(worldId);
      final candidates = await _getCandidates(worldId, alreadySpotlighted);

      if (candidates.isEmpty) {
        _cache[todayKey] = _SpotlightCache(residentId: null);
        return null;
      }

      candidates.sort((a, b) {
        final scoreA = _calculateScore(a);
        final scoreB = _calculateScore(b);
        return scoreB.compareTo(scoreA);
      });

      final selected = candidates.first;
      await _recordSpotlight(selected.id, worldId);
      _cache[todayKey] = _SpotlightCache(residentId: selected.id);

      return selected;
    } catch (_) {
      _cache[todayKey] = _SpotlightCache(residentId: null);
      return null;
    }
  }

  static Future<List<String>> _getRecentlySpotlighted(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final data = await client
        .from('spotlight_history')
        .select('resident_id')
        .eq('world_id', worldId)
        .gte('spotlighted_at', sevenDaysAgo.toIso8601String());
    return (data as List)
        .map((e) => e['resident_id'] as String)
        .toList();
  }

  static Future<List<Resident>> _getCandidates(
    String worldId,
    List<String> excludedIds,
  ) async {
    if (!isSupabaseConfigured()) return [];
    final allResidents = await _getAllWorldResidents(worldId);
    return allResidents.where((r) => !excludedIds.contains(r.id)).toList();
  }

  static Future<List<Resident>> _getAllWorldResidents(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('profiles')
        .select()
        .contains('joined_world_ids', '["$worldId"]')
        .limit(100);
    return (data as List)
        .map((e) => _residentFromProfile(e))
        .toList();
  }

  static Resident _residentFromProfile(Map<String, dynamic> data) => Resident(
    id: data['id'] ?? '',
    name: data['name'] ?? 'Member',
    tier: ResidentTier.fromValue(data['tier'] ?? 1),
    bio: data['bio'] ?? '',
    avatarUrl: data['avatar_url'] ?? '',
    profession: data['profession'],
    decorations: List<String>.from(data['decorations'] ?? []),
    lastCheckIn: data['last_check_in'] as String?,
    streakCount: (data['streak_count'] as int?) ?? 0,
    streakShields: (data['streak_shields'] as int?) ?? 0,
    following: List<String>.from(data['following'] ?? []),
    joinedWorldIds: List<String>.from(data['joined_world_ids'] ?? []),
    referredBy: data['referred_by'] as String?,
    sovereignCoins: (data['sovereign_coins'] as int?) ?? 100,
    onboardingCompleted: data['onboarding_completed'] ?? false,
    gateCompleted: data['gate_completed'] ?? false,
    avatarFrameId: data['avatar_frame_id'] as String?,
  );

  static double _calculateScore(Resident resident) {
    double score = 0;
    score += resident.streakCount * 2;
    if (resident.lastCheckIn != null) {
      final daysSince = DateTime.now().difference(
        DateTime.parse(resident.lastCheckIn!),
      ).inDays;
      if (daysSince <= 7) score += 20;
      else if (daysSince <= 14) score += 10;
    }
    return score;
  }

  static Future<void> _recordSpotlight(String residentId, String worldId) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('spotlight_history').insert({
      'resident_id': residentId,
      'world_id': worldId,
      'spotlighted_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Resident?> _fetchResident(String residentId) async {
    if (!isSupabaseConfigured()) return null;
    return ProfileService.getProfile(residentId);
  }
}

class _SpotlightCache {
  final String? residentId;
  const _SpotlightCache({this.residentId});
}
