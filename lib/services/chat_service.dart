import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/id_generator.dart';
import 'supabase.dart';

class ChatService {
  static Future<Map<String, dynamic>?> getOrCreateRoom(
    String residentId,
    String otherResidentId,
  ) async {
    if (!isSupabaseConfigured()) return null;
    final client = await getSupabase();
    final ids = [residentId, otherResidentId]..sort();
    final existing = await client
        .from('chat_rooms')
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
    await client.from('chat_rooms').insert(room);
    return room;
  }

  static Future<List<Map<String, dynamic>>> getRooms(String residentId) async {
    if (!isSupabaseConfigured()) return [];
    final client = await getSupabase();
    final data = await client
        .from('chat_rooms')
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
    final client = await getSupabase();
    await client.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
    await client.from('chat_rooms').update({
      'last_message': content,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', roomId);
  }

  static Future<List<Map<String, dynamic>>> getMessages(String roomId, {int limit = 100}) async {
    if (!isSupabaseConfigured()) return [];
    final client = await getSupabase();
    final data = await client
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static void subscribeToMessages(
    String roomId,
    void Function(Map<String, dynamic> message) onInsert,
  ) {
    if (!isSupabaseConfigured()) return;
    final client = Supabase.instance.client;
    client
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
  }
}
