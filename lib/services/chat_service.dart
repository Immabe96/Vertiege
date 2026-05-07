import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/id_generator.dart';
import 'moderation_filter.dart';
import 'supabase.dart';

class ChatService {
  static Future<Map<String, dynamic>?> getOrCreateRoom(
    String residentId,
    String otherResidentId,
  ) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final ids = [residentId, otherResidentId]..sort();
    final existing = await client
        .from('dm_rooms')
        .select()
        .contains('resident_ids', ids)
        .maybeSingle();

    if (existing != null) return existing;

    final room = {
      'id': generateId(),
      'resident_ids': ids,
      'last_message': '',
      'last_message_at': DateTime.now().toIso8601String(),
    };
    await client.from('dm_rooms').insert(room);
    return room;
  }

  static Future<List<Map<String, dynamic>>> getRooms(String residentId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('dm_rooms')
        .select()
        .contains('resident_ids', [residentId])
        .order('last_message_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String content,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
    await client.from('dm_rooms').update({
      'last_message': content,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', roomId);
  }

  static Future<List<Map<String, dynamic>>> getMessages(String roomId, {int limit = 100}) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static RealtimeChannel? subscribeToMessages(
    String roomId,
    void Function(Map<String, dynamic> message) onInsert,
  ) {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final channel = client
        .channel('chat_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'room_id', value: roomId),
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe();
    return channel;
  }

  // --- Channel messages (world channels) ---

  static Future<void> sendChannelMessage({
    required String channelId,
    required String senderId,
    required String senderName,
    required String worldId,
    required String content,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();

    // Run The Sentinel moderation filter before sending
    final moderationResult = ModerationFilter.checkContent(content);
    final isFlagged = moderationResult != null;

    await client.from('channel_messages').insert({
      'id': generateId(),
      'channel_id': channelId,
      'sender_id': senderId,
      'sender_name': senderName,
      'world_id': worldId,
      'content': content,
      'flagged': isFlagged,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getChannelMessages(
    String channelId, {
    int limit = 100,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('channel_messages')
        .select()
        .eq('channel_id', channelId)
        .order('created_at', ascending: true)
        .limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static RealtimeChannel? subscribeToChannelMessages(
    String channelId,
    void Function(Map<String, dynamic> message) onInsert,
  ) {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    return client
        .channel('channel_$channelId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'channel_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_id',
            value: channelId,
          ),
          callback: (payload) {
            onInsert(payload.newRecord);
          },
        )
        .subscribe();
  }
}
