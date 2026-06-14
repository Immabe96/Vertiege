import 'supabase.dart';

class LeaderboardEntry {
  final String userId;
  final String name;
  final String avatarUrl;
  final int tier;
  final int totalXp;
  final int prestigeStars;
  final int streakCount;
  final int verifiedAchievements;
  final String? title;
  final bool leaderboardOptOut;

  const LeaderboardEntry({
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.tier,
    required this.totalXp,
    required this.prestigeStars,
    required this.streakCount,
    this.verifiedAchievements = 0,
    this.title,
    this.leaderboardOptOut = false,
  });

  factory LeaderboardEntry.fromProfile(Map<String, dynamic> data) {
    return LeaderboardEntry(
      userId: data['id'] ?? '',
      name: data['name'] ?? 'Member',
      avatarUrl: data['avatar_url'] ?? '',
      tier: (data['tier'] as num?)?.toInt() ?? 1,
      totalXp: (data['total_xp'] as num?)?.toInt() ?? 0,
      prestigeStars: (data['prestige_stars'] as num?)?.toInt() ?? 0,
      streakCount: (data['streak_count'] as num?)?.toInt() ?? 0,
      title: data['display_title'] as String?,
      leaderboardOptOut: data['leaderboard_opt_out'] ?? false,
    );
  }

  int get rankScore => totalXp * 1000 + prestigeStars * 100 + streakCount;
}

class LeaderboardService {
  static Future<List<LeaderboardEntry>> getGlobalLeaderboard({
    int limit = 50,
    int offset = 0,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('profiles')
        .select(
          'id, name, avatar_url, tier, total_xp, prestige_stars, streak_count, display_title, leaderboard_opt_out',
        )
        .eq('leaderboard_opt_out', false)
        .order('total_xp', ascending: false)
        .order('prestige_stars', ascending: false)
        .order('streak_count', ascending: false)
        .range(offset, offset + limit - 1)
        .timeout(const Duration(seconds: 10));
    return (data as List)
        .map((e) => LeaderboardEntry.fromProfile(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<LeaderboardEntry>> getAchievementLeaderboard({
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('profiles')
        .select(
          'id, name, avatar_url, tier, total_xp, prestige_stars, streak_count, display_title, leaderboard_opt_out',
        )
        .eq('leaderboard_opt_out', false)
        .order('total_xp', ascending: false)
        .limit(limit)
        .timeout(const Duration(seconds: 10));
    return (data as List)
        .map((e) => LeaderboardEntry.fromProfile(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<LeaderboardEntry>> getReferralLeaderboard({
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('profiles')
        .select(
          'id, name, avatar_url, tier, total_xp, prestige_stars, streak_count, successful_referrals, display_title, leaderboard_opt_out',
        )
        .eq('leaderboard_opt_out', false)
        .gt('successful_referrals', 0)
        .order('successful_referrals', ascending: false)
        .order('total_xp', ascending: false)
        .limit(limit)
        .timeout(const Duration(seconds: 10));
    return (data as List)
        .map((e) => LeaderboardEntry.fromProfile(e as Map<String, dynamic>))
        .toList();
  }

  static Future<LeaderboardEntry?> getMyRank(String userId) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('profiles')
        .select(
          'id, name, avatar_url, tier, total_xp, prestige_stars, streak_count, display_title, leaderboard_opt_out',
        )
        .eq('id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));
    if (data == null) return null;
    return LeaderboardEntry.fromProfile(data);
  }
}
