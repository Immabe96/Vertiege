import 'package:flutter/foundation.dart';
import '../models/poll.dart';
import 'supabase.dart';

class PollService {
  static Future<List<WorldPoll>> getPolls(
    String worldId, {
    bool activeOnly = false,
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    var query = client
        .from('world_polls')
        .select()
        .eq('world_id', worldId);

    if (activeOnly) {
      query = query.eq('is_closed', false);
    }

    final data = await query
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => WorldPoll.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<WorldPoll?> createPoll({
    required String worldId,
    required String question,
    required List<String> options,
    String? channelId,
    int? expiresAt,
  }) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final result = await client
        .from('world_polls')
        .insert({
          'world_id': worldId,
          'question': question,
          'options': options,
          if (channelId != null) 'channel_id': channelId,
          if (expiresAt != null) 'expires_at': expiresAt,
          'created_by': userId,
        })
        .select()
        .single();

    return WorldPoll.fromSupabase(result);
  }

  static Future<bool> voteOnPoll(String pollId, int optionIndex) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await client.rpc('vote_on_poll', params: {
        'p_poll_id': pollId,
        'p_option_index': optionIndex,
        'p_user_id': userId,
      });
      return true;
    } catch (e) {
      debugPrint('PollService.voteOnPoll error: $e');
      return false;
    }
  }

  static Future<bool> closePoll(String pollId) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client
        .from('world_polls')
        .update({'is_closed': true})
        .eq('id', pollId);
    return true;
  }

  static Future<bool> deletePoll(String pollId) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client.from('world_polls').delete().eq('id', pollId);
    return true;
  }
}
