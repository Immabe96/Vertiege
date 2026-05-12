import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/channel.dart';
import '../models/notification.dart';
import '../utils/id_generator.dart';
import '../utils/text_parser.dart';
import 'moderation_filter.dart';
import 'notification_service.dart';
import 'supabase.dart';
import 'world_service.dart';

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
    required String senderName,
    required String content,
    String? senderAvatar,
    String? imageUrl,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    final payload = <String, dynamic>{
      'room_id': roomId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      await client.from('chat_messages').insert(payload);
    } on PostgrestException catch (e) {
      final missingDisplayColumns =
          e.message.contains('sender_name') ||
          e.message.contains('sender_avatar') ||
          e.message.contains('image_url');
      if (!missingDisplayColumns) rethrow;
      await client.from('chat_messages').insert({
        'room_id': roomId,
        'sender_id': senderId,
        'content': content,
        'created_at': payload['created_at'],
      });
    }
    await client
        .from('dm_rooms')
        .update({
          'last_message': content.isNotEmpty ? content : 'Image',
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .eq('id', roomId);
  }

  static Future<List<Map<String, dynamic>>> getMessages(
    String roomId, {
    int limit = 100,
  }) async {
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
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
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
    String? senderAvatar,
    String? imageUrl,
  }) async {
    if (!isSupabaseConfigured()) throw Exception('Supabase not configured');
    final client = getSupabase();

    // Run The Sentinel moderation filter before sending
    final moderationResult = ModerationFilter.checkContent(content);
    final isFlagged = moderationResult != null;

    final payload = <String, dynamic>{
      'id': generateId(),
      'channel_id': channelId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'world_id': worldId,
      'content': content,
      'image_url': imageUrl,
      'flagged': isFlagged,
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      await client.from('channel_messages').insert(payload);
    } on PostgrestException catch (e) {
      final missingOptionalColumns =
          e.message.contains('sender_avatar') ||
          e.message.contains('image_url') ||
          e.message.contains('flagged');
      if (!missingOptionalColumns) rethrow;
      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('sender_avatar')
        ..remove('image_url')
        ..remove('flagged');
      await client.from('channel_messages').insert(fallbackPayload);
    }

    // Broadcast @AllResidents notifications
    if (TextParser.containsAllResidents(content)) {
      _broadcastMentionNotifications(
        worldId: worldId,
        senderId: senderId,
        senderName: senderName,
      );
    }
  }

  static Future<void> _broadcastMentionNotifications({
    required String worldId,
    required String senderId,
    required String senderName,
  }) async {
    final members = await WorldService.getMembers(worldId);
    for (final member in members) {
      final residentId = member['resident_id'] ?? member['id'] ?? '';
      if (residentId.isEmpty || residentId == senderId) continue;
      final notification = AppNotification(
        id: generateId(),
        type: NotificationType.mention,
        message: '$senderName mentioned everyone',
        worldId: worldId,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      await NotificationService.createNotification(
        recipientId: residentId,
        notification: notification,
      );
    }
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

  static Future<Map<String, dynamic>?> getChannelMessage(
    String messageId,
  ) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('channel_messages')
        .select()
        .eq('id', messageId)
        .maybeSingle();
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  // ── Channel read tracking ──────────────────────────────

  static Future<void> markChannelRead({
    required String channelId,
    required String residentId,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('channel_reads').upsert({
      'resident_id': residentId,
      'channel_id': channelId,
      'last_read_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, DateTime>> getChannelReads(
    String residentId,
  ) async {
    if (!isSupabaseConfigured()) return {};
    final client = getSupabase();
    final data = await client
        .from('channel_reads')
        .select('channel_id, last_read_at')
        .eq('resident_id', residentId);
    final map = <String, DateTime>{};
    for (final row in (data as List)) {
      final channelId = row['channel_id'] as String?;
      final ts = DateTime.tryParse(row['last_read_at'] ?? '');
      if (channelId != null && ts != null) {
        map[channelId] = ts;
      }
    }
    return map;
  }

  // ── Pinned messages ──────────────────────────────────────

  static Future<void> pinMessage({
    required String messageId,
    required bool isPinned,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client
        .from('channel_messages')
        .update({'is_pinned': isPinned})
        .eq('id', messageId);
  }

  static Future<List<Map<String, dynamic>>> getPinnedMessages(
    String channelId,
  ) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('channel_messages')
        .select()
        .eq('channel_id', channelId)
        .eq('is_pinned', true)
        .order('created_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<DateTime?> getLastMessageTimestamp(String channelId) async {
    return _getLatestChannelMessageTimestamp(channelId);
  }

  static Future<Map<String, DateTime>> getLatestChannelMessageTimestamps(
    List<String> channelIds,
  ) async {
    final ids = channelIds.toSet().where((id) => id.isNotEmpty).toList();
    if (!isSupabaseConfigured() || ids.isEmpty) return {};
    final entries = await Future.wait(
      ids.map(
        (id) async => MapEntry(id, await _getLatestChannelMessageTimestamp(id)),
      ),
    );
    final latest = <String, DateTime>{};
    for (final entry in entries) {
      final createdAt = entry.value;
      if (createdAt != null) latest[entry.key] = createdAt;
    }
    return latest;
  }

  static Future<DateTime?> _getLatestChannelMessageTimestamp(
    String channelId,
  ) async {
    if (!isSupabaseConfigured() || channelId.isEmpty) return null;
    final data = await getSupabase()
        .from('channel_messages')
        .select('created_at')
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data == null ? null : DateTime.tryParse(data['created_at'] ?? '');
  }

  // ── Wards (districts) ────────────────────────────────────

  static Future<List<District>> getDistricts(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('districts')
        .select()
        .eq('world_id', worldId)
        .order('position');
    return (data as List)
        .map((e) => District.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createDistrict({
    required String worldId,
    required String name,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    final maxPos = await client
        .from('districts')
        .select('position')
        .eq('world_id', worldId)
        .order('position', ascending: false)
        .limit(1)
        .maybeSingle();
    final nextPos = (maxPos?['position'] ?? -1) + 1;
    await client.from('districts').insert({
      'id': generateId(),
      'world_id': worldId,
      'name': name,
      'position': nextPos,
    });
  }

  static Future<void> renameDistrict({
    required String districtId,
    required String name,
  }) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase()
        .from('districts')
        .update({'name': name})
        .eq('id', districtId);
  }

  // ── Threads ─────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getThreadMessages(
    String threadId,
  ) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('channel_messages')
        .select()
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<void> sendThreadReply({
    required String channelId,
    required String senderId,
    required String senderName,
    required String worldId,
    required String content,
    required String threadId,
    String? senderAvatar,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    final payload = <String, dynamic>{
      'id': generateId(),
      'channel_id': channelId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'world_id': worldId,
      'content': content,
      'thread_id': threadId,
      'created_at': DateTime.now().toIso8601String(),
    };
    try {
      await client.from('channel_messages').insert(payload);
    } on PostgrestException catch (e) {
      if (!e.message.contains('sender_avatar')) rethrow;
      await client
          .from('channel_messages')
          .insert(Map<String, dynamic>.from(payload)..remove('sender_avatar'));
    }
    // Increment thread count on parent
    await client.rpc('increment_thread_count', params: {'msg_id': threadId});
  }

  static Future<void> deleteDistrict(String districtId) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase().from('districts').delete().eq('id', districtId);
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
