import 'package:flutter/foundation.dart';
import '../models/challenge.dart';
import 'supabase.dart';

class ChallengeService {
  static Future<List<WorldChallenge>> getChallenges(
    String worldId, {
    bool activeOnly = false,
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    var query = client
        .from('world_challenges')
        .select()
        .eq('world_id', worldId);

    if (activeOnly) {
      query = query.eq('is_active', true);
    }

    final data = await query
        .order('expires_at', ascending: true)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => WorldChallenge.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<WorldChallenge?> createChallenge({
    required String worldId,
    required String title,
    required String description,
    String challengeType = 'individual',
    required int targetValue,
    int rewardXp = 0,
    int rewardCurrency = 0,
    DateTime? expiresAt,
  }) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final result = await client
        .from('world_challenges')
        .insert({
          'world_id': worldId,
          'title': title,
          'description': description,
          'challenge_type': challengeType,
          'target_value': targetValue,
          'reward_xp': rewardXp,
          'reward_currency': rewardCurrency,
          if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
          'created_by': userId,
        })
        .select()
        .single();

    return WorldChallenge.fromSupabase(result);
  }

  static Future<bool> updateProgress(String challengeId, int contribution) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    try {
      await client.rpc('update_challenge_progress', params: {
        'p_challenge_id': challengeId,
        'p_contribution': contribution,
      });
      return true;
    } catch (e) {
      debugPrint('ChallengeService.updateProgress error: $e');
      return false;
    }
  }

  static Future<bool> toggleChallenge(String challengeId, bool isActive) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client
        .from('world_challenges')
        .update({'is_active': isActive})
        .eq('id', challengeId);
    return true;
  }

  static Future<bool> deleteChallenge(String challengeId) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client.from('world_challenges').delete().eq('id', challengeId);
    return true;
  }
}
