import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/channel.dart';
import '../models/notification.dart';
import '../utils/id_generator.dart';
import '../utils/text_parser.dart';
import 'moderation_filter.dart';
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
    required String messageId,
    required String roomId,
    required String senderId,
    required String senderName,
    required String content,
    String? senderAvatar,
    String? imageUrl,
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToSenderName,
    String? replyToContent,
    int? autoDeleteAfterSeconds,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    final payload = <String, dynamic>{
      'id': messageId,
      'room_id': roomId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    };
    if (replyToMessageId != null) {
      payload['reply_to_message_id'] = replyToMessageId;
      payload['reply_to_sender_id'] = replyToSenderId;
      payload['reply_to_sender_name'] = replyToSenderName;
      payload['reply_to_content'] = replyToContent;
    }
    if (autoDeleteAfterSeconds != null) {
      payload['auto_delete_after_seconds'] = autoDeleteAfterSeconds;
    }
    try {
      await client.from('chat_messages').insert(payload);
    } on PostgrestException catch (e) {
      final missingDisplayColumns =
          e.message.contains('sender_name') ||
          e.message.contains('sender_avatar') ||
          e.message.contains('image_url') ||
          e.message.contains('reply_to');
      if (!missingDisplayColumns) rethrow;
      final fallback = <String, dynamic>{
        'id': messageId,
        'room_id': roomId,
        'sender_id': senderId,
        'content': content,
        'created_at': payload['created_at'],
      };
      if (autoDeleteAfterSeconds != null) {
        fallback['auto_delete_after_seconds'] = autoDeleteAfterSeconds;
      }
      await client.from('chat_messages').insert(fallback);
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
    int? autoDeleteSeconds,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .limit(limit);
    final raw = (data as List).cast<Map<String, dynamic>>();
    final now = DateTime.now();
    return raw.where((msg) {
      final autoDelete = msg['auto_delete_after_seconds'] as int?;
      if (autoDelete == null) return true;
      final createdAt = DateTime.tryParse(msg['created_at'] ?? '');
      if (createdAt == null) return true;
      return createdAt.add(Duration(seconds: autoDelete)).isAfter(now);
    }).toList();
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

  static Future<Map<String, dynamic>> sendChannelMessage({
    required String messageId,
    required String channelId,
    required String senderId,
    required String senderName,
    required String worldId,
    required String content,
    String? senderAvatar,
    String? imageUrl,
  }) async {
    if (!isSupabaseConfigured()) throw Exception('Supabase not configured');
    if (worldId.trim().isEmpty ||
        channelId.trim().isEmpty ||
        senderId.trim().isEmpty) {
      throw ArgumentError('Channel messages require non-empty cloud ids.');
    }
    final client = getSupabase();

    final channel = await client
        .from('channels')
        .select('id, world_id')
        .eq('id', channelId)
        .eq('world_id', worldId)
        .maybeSingle();
    if (channel == null) {
      throw StateError('Channel is not available for this world.');
    }

    final membership = await client
        .from('world_members')
        .select('world_id')
        .eq('world_id', worldId)
        .eq('resident_id', senderId)
        .maybeSingle();
    if (membership == null) {
      throw StateError('Join this world before sending messages.');
    }

    // Run The Sentinel moderation filter before sending
    final moderationResult = ModerationFilter.checkContent(content);
    final isFlagged = moderationResult != null;

    final payload = <String, dynamic>{
      'id': messageId,
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
      final inserted = await client
          .from('channel_messages')
          .insert(payload)
          .select()
          .single();
      if (TextParser.containsAllResidents(content)) {
        unawaited(
          _broadcastMentionNotifications(
            worldId: worldId,
            senderId: senderId,
            senderName: senderName,
          ),
        );
      }
      return Map<String, dynamic>.from(inserted);
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
      final inserted = await client
          .from('channel_messages')
          .insert(fallbackPayload)
          .select()
          .single();
      if (TextParser.containsAllResidents(content)) {
        unawaited(
          _broadcastMentionNotifications(
            worldId: worldId,
            senderId: senderId,
            senderName: senderName,
          ),
        );
      }
      return Map<String, dynamic>.from(inserted);
    }
  }

  static Future<void> _broadcastMentionNotifications({
    required String worldId,
    required String senderId,
    required String senderName,
  }) async {
    final members = await WorldService.getMembers(worldId);
    final notifications = <Map<String, dynamic>>[];
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
      notifications.add(notification.toSupabase(residentId));
    }
    if (notifications.isNotEmpty) {
      final client = getSupabase();
      await client.from('notifications').insert(notifications);
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
    final response = await getSupabase().rpc(
      'get_latest_channel_message_timestamps',
      params: {'p_channel_ids': ids},
    );
    final latest = <String, DateTime>{};
    if (response is List) {
      for (final row in response) {
        final cid = row['channel_id'] as String?;
        final tsStr = row['created_at']?.toString();
        if (cid != null && tsStr != null) {
          final ts = DateTime.tryParse(tsStr);
          if (ts != null) {
            latest[cid] = ts;
          }
        }
      }
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
    required String messageId,
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
      'id': messageId,
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

  // F-02: Reactions
  static Future<void> toggleReaction({
    required String messageId,
    required String userId,
    required String emoji,
    required bool add,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    final dmMessage = await client
        .from('chat_messages')
        .select('reactions')
        .eq('id', messageId)
        .maybeSingle();
    if (dmMessage != null) {
      final raw = dmMessage['reactions'];
      final reactions = raw is Map<String, dynamic>
          ? raw.map((key, value) => MapEntry(key, List<String>.from(value)))
          : <String, List<String>>{};
      final users = List<String>.from(reactions[emoji] ?? const <String>[]);
      if (add) {
        if (!users.contains(userId)) users.add(userId);
        reactions[emoji] = users;
      } else {
        users.remove(userId);
        if (users.isEmpty) {
          reactions.remove(emoji);
        } else {
          reactions[emoji] = users;
        }
      }
      await client
          .from('chat_messages')
          .update({'reactions': reactions})
          .eq('id', messageId);
      return;
    }
    if (add) {
      await client.rpc(
        'add_reaction',
        params: {'msg_id': messageId, 'emoji': emoji, 'resident_id': userId},
      );
    } else {
      await client.rpc(
        'remove_reaction',
        params: {'msg_id': messageId, 'emoji': emoji, 'resident_id': userId},
      );
    }
  }

  // F-03: Edit message
  static Future<void> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client
        .from('chat_messages')
        .update({
          'content': newContent,
          'is_edited': true,
          'edited_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId);
  }

  // F-03: Delete message
  static Future<void> deleteMessage({required String messageId}) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client
        .from('chat_messages')
        .update({
          'content': 'This message was deleted',
          'is_deleted': true,
          'image_url': null,
          'reply_to_content': null,
          'reply_to_image_url': null,
        })
        .eq('id', messageId);
  }
}
