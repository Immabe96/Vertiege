import '../models/poll.dart';
import 'supabase.dart';

class PollService {
  static Future<bool> canCreatePoll(String worldId) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    final result = await client.rpc(
      'can_create_world_poll',
      params: {'p_world_id': worldId},
    );
    return result == true;
  }

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
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to create polls.');
    }
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Authentication required to create polls.');
    }

    final result = await client.rpc(
      'create_world_poll',
      params: {
        'p_world_id': worldId,
        'p_question': question,
        'p_options': options,
        'p_channel_id': ?channelId,
        'p_expires_at': ?expiresAt,
      },
    );

    if (result is! Map) {
      throw StateError('Unexpected response creating poll.');
    }
    final map = Map<String, dynamic>.from(result);
    if (map['success'] != true) {
      throw StateError(
        map['error'] as String? ??
            'Polls require Veteran standing or council in this world.',
      );
    }
    final poll = map['poll'];
    if (poll is! Map) {
      throw StateError('Poll was not returned from the server.');
    }
    return WorldPoll.fromSupabase(Map<String, dynamic>.from(poll));
  }

  static Future<bool> voteOnPoll(String pollId, int optionIndex) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to vote on polls.');
    }
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Authentication required to vote on polls.');
    }

    final result = await client.rpc('vote_on_poll_v2', params: {
      'p_poll_id': pollId,
      'p_option_index': optionIndex,
    });
    final map = result as Map<String, dynamic>?;
    final success = map?['success'] == true;
    if (!success) {
      final error = map?['error'] ?? 'Unknown error';
      throw Exception('Poll vote failed: $error');
    }
    return true;
  }

  static Future<bool> closePoll(String pollId) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to close polls.');
    }
    final client = getSupabase();
    await client
        .from('world_polls')
        .update({'is_closed': true})
        .eq('id', pollId);
    return true;
  }

  static Future<bool> deletePoll(String pollId) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to delete polls.');
    }
    final client = getSupabase();
    await client.from('world_polls').delete().eq('id', pollId);
    return true;
  }
}
