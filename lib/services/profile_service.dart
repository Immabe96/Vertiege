import 'package:flutter/foundation.dart';

import '../models/resident.dart';
import '../utils/local_date.dart';
import '../utils/presence_utils.dart';
import 'supabase.dart';
import 'crash_reporter.dart';

class ProfileService {
  static Future<void> upsertProfile(Resident resident) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('profiles').upsert(_toClientWritableProfileRow(resident));
  }

  @visibleForTesting
  static Map<String, dynamic> clientWritableProfileRow(Resident r) =>
      _toClientWritableProfileRow(r);

  /// Fields the mobile client may write; tier/coins/streak are server/RPC managed.
  static Map<String, dynamic> _toClientWritableProfileRow(Resident r) => {
    'id': r.id,
    'name': r.name,
    'bio': r.bio,
    'avatar_url': r.avatarUrl,
    'profession': r.profession,
    'decorations': r.decorations,
    'following': r.following,
    'joined_world_ids': r.joinedWorldIds,
    if (r.referredBy != null) 'referred_by': r.referredBy,
    'onboarding_completed': r.onboardingCompleted,
    'gate_completed': r.gateCompleted,
    if (r.avatarFrameId != null) 'avatar_frame_id': r.avatarFrameId,
    if (r.title != null) 'display_title': r.title,
    'leaderboard_opt_out': r.leaderboardOptOut,
  };

  static Future<void> updateProgressionPreferences({
    required String userId,
    bool? leaderboardOptOut,
    String? displayTitle,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    final patch = <String, dynamic>{};
    if (leaderboardOptOut != null) {
      patch['leaderboard_opt_out'] = leaderboardOptOut;
    }
    if (displayTitle != null) {
      patch['display_title'] = displayTitle.isEmpty ? null : displayTitle;
    }
    if (patch.isEmpty) return;
    await client.from('profiles').update(patch).eq('id', userId);
  }

  static Future<void> syncDeviceTimezone(String userId) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('profiles').update({
      'timezone': deviceTimezoneLabel(),
    }).eq('id', userId);
  }

  static Future<void> patchOnboardingFunnel(
    String userId,
    Map<String, dynamic> funnel,
  ) async {
    if (!isSupabaseConfigured() || funnel.isEmpty) return;
    final client = getSupabase();
    await client.from('profiles').update({
      'onboarding_funnel': funnel,
    }).eq('id', userId);
  }

  static Future<List<String>> getFeaturedAchievementIds(String userId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final row = await client
        .from('profiles')
        .select('featured_achievement_ids')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return [];
    final raw = row['featured_achievement_ids'];
    if (raw is! List) return [];
    return raw.map((e) => e.toString()).toList();
  }

  static Future<List<String>> setFeaturedAchievements(List<String> ids) async {
    if (!isSupabaseConfigured()) return [];
    final trimmed = ids.take(3).toList();
    final raw = await getSupabase().rpc(
      'set_featured_achievements',
      params: {'p_ids': trimmed},
    );
    if (raw is! List) return trimmed;
    return raw.map((e) => e.toString()).toList();
  }

  static Future<Map<String, dynamic>?> getOnboardingFunnel(String userId) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final row = await client
        .from('profiles')
        .select('onboarding_funnel')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    final raw = row['onboarding_funnel'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  /// Server-side daily check-in (F31). Returns null if already checked in today.
  static Future<({int streak, int bonusXp, bool shieldUsed})?>
  recordDailyCheckIn() async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final raw = await client.rpc(
      'record_daily_check_in',
      params: {'p_local_date': localDateKey()},
    );
    if (raw is! Map) return null;
    final data = Map<String, dynamic>.from(raw);
    if (data['already_checked_in'] == true) return null;
    return (
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      bonusXp: (data['bonus_xp'] as num?)?.toInt() ?? 0,
      shieldUsed: data['shield_used'] == true,
    );
  }

  static Future<Resident?> getProfile(String userId) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    final verifiedRoles = await _getVerifiedRoles(userId);
    final joinedWorldIds = await _getJoinedWorldIds(userId, data);
    return _toResident(
      data,
      verifiedRoles: verifiedRoles,
      joinedWorldIds: joinedWorldIds,
    );
  }

  static Future<List<Resident>> searchResidents(
    String query, {
    int limit = 20,
  }) async {
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

  static Resident _toResident(
    Map<String, dynamic> data, {
    List<String> verifiedRoles = const [],
    List<String>? joinedWorldIds,
  }) {
    final totalXp = (data['total_xp'] as num?)?.toInt() ?? 0;
    final tierLevel = (data['tier'] as num?)?.toInt();
    return Resident(
      id: data['id'] ?? '',
      name: data['name'] ?? 'Member',
      tier: tierLevel != null
          ? ResidentTier.fromValue(tierLevel)
          : ResidentTier.fromXp(totalXp),
      bio: data['bio'] ?? '',
      avatarUrl: data['avatar_url'] ?? '',
      profession: data['profession'],
      verifiedRoles: verifiedRoles,
      decorations: List<String>.from(data['decorations'] ?? []),
      lastCheckIn: data['last_check_in'] as String?,
      streakCount: (data['streak_count'] as int?) ?? 0,
      streakShields: (data['streak_shields'] as int?) ?? 0,
      following: List<String>.from(data['following'] ?? []),
      joinedWorldIds:
          joinedWorldIds ?? List<String>.from(data['joined_world_ids'] ?? []),
      worldStandings: _parseWorldStandings(data['world_standings']),
      referredBy: data['referred_by'] as String?,
      sovereignCoins: (data['sovereign_coins'] as int?) ?? 100,
      onboardingCompleted: data['onboarding_completed'] ?? false,
      gateCompleted: data['gate_completed'] ?? false,
      avatarFrameId: data['avatar_frame_id'] as String?,
      totalXp: totalXp,
      prestigeLevel: (data['prestige_level'] as num?)?.toInt() ?? 0,
      prestigeStars: (data['prestige_stars'] as num?)?.toInt() ?? 0,
      referralXpMultiplier:
          (data['referral_xp_multiplier'] as num?)?.toDouble() ?? 1.0,
      successfulReferrals:
          (data['successful_referrals'] as num?)?.toInt() ?? 0,
      lastActivityAt: _parseLastActivityAt(data['last_activity_at']),
      title: data['display_title'] as String? ?? data['title'] as String?,
      leaderboardOptOut: data['leaderboard_opt_out'] == true,
      lastSeenAt: parseLastSeenMs(data['last_seen_at']) ?? 0,
      presenceMode: data['presence_mode'] as String? ?? 'online',
      customStatus: data['custom_status'] as String?,
      coverImageUrl: data['cover_image_url'] as String?,
    );
  }

  static Map<String, WorldStanding> _parseWorldStandings(dynamic value) {
    if (value is! Map) return {};
    return value.map((k, v) {
      final rep = v is Map ? (v['rep'] as num?)?.toInt() ?? 0 : 0;
      return MapEntry(k.toString(), WorldStanding(rep: rep));
    });
  }

  static int _parseLastActivityAt(dynamic value) {
    if (value is int) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  static Future<List<String>> _getVerifiedRoles(String userId) async {
    try {
      final client = getSupabase();
      final data = await client
          .from('verification_submissions')
          .select('profession')
          .eq('resident_id', userId)
          .eq('status', 'verified');
      return (data as List)
          .map((e) => (e as Map<String, dynamic>)['profession']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
    } catch (e, st) {
      // Graceful degradation — profile loads without verified roles.
      CrashReporter.instance.recordError(
        e,
        st,
        hint: 'profile_service getVerifiedRoles',
      );
      return const [];
    }
  }

  static Future<List<String>> _getJoinedWorldIds(
    String userId,
    Map<String, dynamic> profile,
  ) async {
    return List<String>.from(profile['joined_world_ids'] ?? []);
  }
}
