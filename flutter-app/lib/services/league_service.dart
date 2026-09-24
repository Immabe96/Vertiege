import 'package:flutter/material.dart';
import '../services/supabase.dart';

class LeagueService {
  LeagueService._();

  static const leagueTiers = ['bronze', 'silver', 'gold', 'platinum', 'diamond'];
  static const participantsPerLeague = 30;
  static const promotionCount = 7;
  static const demotionCount = 5;

  static Map<String, dynamic>? _cachedSeason;
  static DateTime? _cachedSeasonAt;
  static Future<Map<String, dynamic>>? _seasonInFlight;
  static const _seasonCacheTtl = Duration(minutes: 5);

  /// Clears the in-memory season cache (e.g. after sign-out).
  static void clearSeasonCache() {
    _cachedSeason = null;
    _cachedSeasonAt = null;
    _seasonInFlight = null;
  }

  static Future<Map<String, dynamic>> getCurrentSeason({
    bool forceRefresh = false,
  }) async {
    final cached = _cachedSeason;
    final cachedAt = _cachedSeasonAt;
    if (!forceRefresh &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _seasonCacheTtl) {
      return cached;
    }

    final inFlight = _seasonInFlight;
    if (inFlight != null) return inFlight;

    final future = _fetchCurrentSeason();
    _seasonInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_seasonInFlight, future)) {
        _seasonInFlight = null;
      }
    }
  }

  static Future<Map<String, dynamic>> _fetchCurrentSeason() async {
    final client = getSupabase();
    final response = await client
        .from('league_seasons')
        .select()
        .eq('is_active', true)
        .maybeSingle();

    final season = response ?? await createNewSeason();
    _cachedSeason = season;
    _cachedSeasonAt = DateTime.now();
    return season;
  }

  static Future<Map<String, dynamic>> createNewSeason() async {
    final client = getSupabase();
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day);
    final weekEnd = weekStart.add(const Duration(days: 7));

    final response = await client.from('league_seasons').insert({
      'start_date': weekStart.toIso8601String(),
      'end_date': weekEnd.toIso8601String(),
      'is_active': true,
    }).select().single();

    await client.from('league_seasons').update({'is_active': false}).neq('id', response['id']);

    _cachedSeason = response;
    _cachedSeasonAt = DateTime.now();
    return response;
  }

  static Future<Map<String, dynamic>> getUserLeague(String userId) async {
    final client = getSupabase();
    final season = await getCurrentSeason();
    final seasonId = season['id'] as String?;
    if (seasonId == null) return {};

    final response = await client
        .from('league_participants')
        .select('*, league_seasons(*)')
        .eq('user_id', userId)
        .eq('season_id', seasonId)
        .maybeSingle();

    if (response == null) return {};
    return response;
  }

  static Future<List<Map<String, dynamic>>> getLeagueStandings(
    String leagueTier,
  ) async {
    final client = getSupabase();
    final season = await getCurrentSeason();
    final seasonId = season['id'] as String?;
    if (seasonId == null) return [];

    final response = await client
        .from('league_participants')
        .select('user_id, profiles(name, avatar_url), weekly_xp, league_tier')
        .eq('league_tier', leagueTier)
        .eq('season_id', seasonId)
        .order('weekly_xp', ascending: false)
        .order('updated_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  static Future<int> addXP(String userId, int amount) async {
    final client = getSupabase();
    final response = await client.rpc(
      'add_league_xp',
      params: {'p_user_id': userId, 'p_amount': amount},
    );
    return (response is int) ? response : 0;
  }

  /// Weekly reset runs on the server (cron). Not exposed to the client.
  @Deprecated('Server-only cron job')
  static Future<void> processWeeklyReset() async {
    throw UnsupportedError(
      'process_league_reset is not callable from the app',
    );
  }

  static Future<void> assignNewUserLeague(String userId) async {
    final client = getSupabase();
    final season = await getCurrentSeason();

    await client.from('league_participants').insert({
      'season_id': season['id'],
      'user_id': userId,
      'league_tier': 'bronze',
      'weekly_xp': 0,
    });
  }

  static int getLeagueTierIndex(String tier) {
    return leagueTiers.indexOf(tier.toLowerCase());
  }

  static String getNextTier(String tier) {
    final idx = getLeagueTierIndex(tier);
    if (idx < leagueTiers.length - 1) return leagueTiers[idx + 1];
    return leagueTiers.last;
  }

  static String getPreviousTier(String tier) {
    final idx = getLeagueTierIndex(tier);
    if (idx > 0) return leagueTiers[idx - 1];
    return leagueTiers.first;
  }

  static Color getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      case 'diamond':
        return const Color(0xFFB9F2FF);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  static IconData getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return Icons.shield;
      case 'silver':
        return Icons.shield_outlined;
      case 'gold':
        return Icons.workspace_premium;
      case 'platinum':
        return Icons.auto_awesome;
      case 'diamond':
        return Icons.diamond;
      default:
        return Icons.shield;
    }
  }
}
