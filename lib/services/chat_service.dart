import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/channel.dart';
import '../utils/id_generator.dart';
import '../utils/text_parser.dart';
import 'moderation_filter.dart';
import 'supabase.dart';
import '../utils/presence_utils.dart';

class ChatService {
  /// Canonical DM participant key order (testable).
  static List<String> sortedParticipantIds(String a, String b) {
    final ids = [a, b]..sort();
    return ids;
  }

  static Future<Map<String, dynamic>?> getOrCreateRoom(
    String residentId,
    String otherResidentId,
  ) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final ids = sortedParticipantIds(residentId, otherResidentId);
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
    final rooms = (data as List).cast<Map<String, dynamic>>();
    return _enrichDmRooms(rooms, residentId);
  }

  static Future<List<Map<String, dynamic>>> _enrichDmRooms(
    List<Map<String, dynamic>> rooms,
    String residentId,
  ) async {
    if (rooms.isEmpty || !isSupabaseConfigured()) return rooms;

    final otherIds = <String>{};
    for (final room in rooms) {
      final ids = (room['resident_ids'] as List?)?.cast<String>() ?? [];
      for (final id in ids) {
        if (id != residentId && id.isNotEmpty) otherIds.add(id);
      }
    }
    if (otherIds.isEmpty) return rooms;

    final client = getSupabase();
    final profiles = await client
        .from('profiles')
        .select(
          'id, name, avatar_url, last_seen_at, presence_mode, custom_status',
        )
        .inFilter('id', otherIds.toList());

    final byId = <String, Map<String, dynamic>>{};
    for (final row in (profiles as List).cast<Map<String, dynamic>>()) {
      final id = row['id'] as String?;
      if (id != null) byId[id] = row;
    }

    final reads = await getDmReads(residentId);
    final roomIds = rooms
        .map((r) => r['id'] as String?)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    final latestSenders = await _latestDmMessageSenders(roomIds);

    return rooms.map((room) {
      final ids = (room['resident_ids'] as List?)?.cast<String>() ?? [];
      final otherId = ids.firstWhere(
        (id) => id != residentId,
        orElse: () => ids.isNotEmpty ? ids.first : '',
      );
      final profile = otherId.isEmpty ? null : byId[otherId];
      final roomId = room['id'] as String? ?? '';
      final unreadCount = _dmUnreadCount(
        roomId: roomId,
        residentId: residentId,
        lastMessageAt: room['last_message_at'],
        lastReadAt: reads[roomId],
        latestSenderId: latestSenders[roomId],
      );

      if (profile == null) {
        return {...room, 'unread_count': unreadCount};
      }

      return {
        ...room,
        'other_name': profile['name'] ?? room['other_name'],
        'other_avatar': profile['avatar_url'] ?? room['other_avatar'],
        'other_last_seen_at': parseLastSeenMs(profile['last_seen_at']),
        'other_presence_mode': profile['presence_mode'],
        'other_custom_status': profile['custom_status'],
        'unread_count': unreadCount,
      };
    }).toList();
  }

  static int _dmUnreadCount({
    required String roomId,
    required String residentId,
    required dynamic lastMessageAt,
    required DateTime? lastReadAt,
    required String? latestSenderId,
  }) {
    if (roomId.isEmpty) return 0;
    final lastMsgAt = DateTime.tryParse('$lastMessageAt');
    if (lastMsgAt == null) return 0;
    if (latestSenderId == residentId) return 0;
    if (lastReadAt != null && !lastMsgAt.isAfter(lastReadAt)) return 0;
    return 1;
  }

  static Future<Map<String, String>> _latestDmMessageSenders(
    List<String> roomIds,
  ) async {
    if (!isSupabaseConfigured() || roomIds.isEmpty) return {};
    final client = getSupabase();
    final data = await client
        .from('chat_messages')
        .select('room_id, sender_id, created_at')
        .inFilter('room_id', roomIds)
        .order('created_at', ascending: false);
    final seen = <String>{};
    final senders = <String, String>{};
    for (final row in data) {
      final roomId = row['room_id'] as String?;
      final senderId = row['sender_id'] as String?;
      if (roomId == null || senderId == null || !seen.add(roomId)) continue;
      senders[roomId] = senderId;
    }
    return senders;
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
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is not configured; message queued locally.');
    }
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
      if (imageUrl != null) fallback['image_url'] = imageUrl;
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
    DateTime? before,
    int? autoDeleteSeconds,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    var query = client.from('chat_messages').select().eq('room_id', roomId);
    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }
    final data = await query
        .order('created_at', ascending: false)
        .limit(limit);
    final raw = (data as List).cast<Map<String, dynamic>>().reversed.toList();
    final now = DateTime.now();
    return raw.where((msg) {
      final autoDelete = msg['auto_delete_after_seconds'] as int?;
      if (autoDelete == null) return true;
      final createdAt = DateTime.tryParse(msg['created_at'] ?? '');
      if (createdAt == null) return true;
      return createdAt.add(Duration(seconds: autoDelete)).isAfter(now);
    }).toList();
  }

  /// Single inbox channel: postgres UPDATE on [dm_rooms] for rooms the user is in.
  static RealtimeChannel? subscribeToDmRoomListUpdates(
    String residentId,
    void Function(Map<String, dynamic> room) onUpdate,
  ) {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final channel = client
        .channel('dm_rooms_list_$residentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'dm_rooms',
          callback: (payload) {
            final record = payload.newRecord;
            final ids =
                (record['resident_ids'] as List?)?.cast<String>() ?? const [];
            if (!ids.contains(residentId)) return;
            onUpdate(record);
          },
        )
        .subscribe();
    return channel;
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

    // Server + local moderation before send
    final moderationResult =
        await ModerationFilter.checkContentAsync(content, surface: 'chat');
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
      unawaited(
        _fanOutMentionNotifications(
          worldId: worldId,
          channelId: channelId,
          senderId: senderId,
          senderName: senderName,
          content: content,
        ),
      );
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
      unawaited(
        _fanOutMentionNotifications(
          worldId: worldId,
          channelId: channelId,
          senderId: senderId,
          senderName: senderName,
          content: content,
        ),
      );
      return Map<String, dynamic>.from(inserted);
    }
  }

  static Future<void> _fanOutMentionNotifications({
    required String worldId,
    required String channelId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    if (TextParser.containsAllResidents(content)) {
      await _broadcastMentionNotifications(
        worldId: worldId,
        senderId: senderId,
        senderName: senderName,
      );
    }
    final handles = TextParser.extractResidentMentionHandles(content);
    if (handles.isEmpty) return;
    await _broadcastResidentMentionNotifications(
      worldId: worldId,
      channelId: channelId,
      senderId: senderId,
      handles: handles,
      preview: '$senderName mentioned you',
    );
  }

  static Future<void> _broadcastMentionNotifications({
    required String worldId,
    required String senderId,
    required String senderName,
  }) async {
    if (!isSupabaseConfigured()) return;
    try {
      await getSupabase().rpc(
        'broadcast_world_mention_notifications',
        params: {
          'p_world_id': worldId,
          'p_sender_id': senderId,
          'p_message': '$senderName mentioned everyone',
        },
      );
    } catch (_) {
      // Mention fan-out is best-effort; channel message already persisted.
    }
  }

  static Future<void> _broadcastResidentMentionNotifications({
    required String worldId,
    required String channelId,
    required String senderId,
    required List<String> handles,
    required String preview,
  }) async {
    if (!isSupabaseConfigured()) return;
    try {
      await getSupabase().rpc(
        'broadcast_channel_mention_notifications',
        params: {
          'p_world_id': worldId,
          'p_channel_id': channelId,
          'p_sender_id': senderId,
          'p_mention_handles': handles,
          'p_message': preview,
        },
      );
    } catch (_) {
      // Best-effort per-resident mention fan-out.
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
        .isFilter('thread_id', null)
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

  static Future<void> markDmRead({
    required String roomId,
    required String residentId,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    final now = DateTime.now().toUtc().toIso8601String();
    await client.from('dm_reads').upsert({
      'resident_id': residentId,
      'room_id': roomId,
      'last_read_at': now,
    });
    unawaited(recordMessageReadsForRoom(roomId: roomId, residentId: residentId));
  }

  static Future<void> recordMessageReadsForRoom({
    required String roomId,
    required String residentId,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    try {
      final data = await client
          .from('chat_messages')
          .select('id')
          .eq('room_id', roomId)
          .neq('sender_id', residentId)
          .limit(200);
      final ids = (data as List)
          .map((row) => row['id'] as String?)
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();
      if (ids.isEmpty) return;
      final now = DateTime.now().toUtc().toIso8601String();
      await client.from('message_reads').upsert(
        ids
            .map(
              (id) => {
                'message_id': id,
                'resident_id': residentId,
                'room_id': roomId,
                'read_at': now,
              },
            )
            .toList(),
      );
    } catch (_) {
      // message_reads is optional; dm_reads still drives unread.
    }
  }

  static Future<DateTime?> getPartnerDmReadAt({
    required String roomId,
    required String partnerId,
  }) async {
    if (!isSupabaseConfigured() || partnerId.isEmpty) return null;
    final client = getSupabase();
    try {
      final data = await client
          .from('dm_reads')
          .select('last_read_at')
          .eq('room_id', roomId)
          .eq('resident_id', partnerId)
          .maybeSingle();
      return DateTime.tryParse(data?['last_read_at'] ?? '');
    } catch (_) {
      return null;
    }
  }

  static RealtimeChannel? subscribeToPartnerDmRead({
    required String roomId,
    required String partnerId,
    required void Function(DateTime readAt) onUpdate,
  }) {
    if (!isSupabaseConfigured() || partnerId.isEmpty) return null;
    final client = getSupabase();
    return client
        .channel('dm_reads_${roomId}_$partnerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'dm_reads',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'resident_id',
            value: partnerId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record['room_id'] != roomId) return;
            final ts = DateTime.tryParse(record['last_read_at'] ?? '');
            if (ts != null) onUpdate(ts);
          },
        )
        .subscribe();
  }

  static Future<Map<String, DateTime>> getDmReads(String residentId) async {
    if (!isSupabaseConfigured()) return {};
    final client = getSupabase();
    try {
      final data = await client
          .from('dm_reads')
          .select('room_id, last_read_at')
          .eq('resident_id', residentId);
      final map = <String, DateTime>{};
      for (final row in (data as List)) {
        final roomId = row['room_id'] as String?;
        final ts = DateTime.tryParse(row['last_read_at'] ?? '');
        if (roomId != null && ts != null) {
          map[roomId] = ts;
        }
      }
      return map;
    } catch (_) {
      final channelReads = await getChannelReads(residentId);
      return channelReads;
    }
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
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is not configured; pin was not saved.');
    }
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

  static Future<void> incrementThreadCount(String threadId) async {
    if (!isSupabaseConfigured() || threadId.isEmpty) return;
    try {
      await getSupabase().rpc(
        'increment_thread_count',
        params: {'msg_id': threadId},
      );
    } catch (_) {}
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
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is not configured; reply was not saved.');
    }
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
    void Function(Map<String, dynamic> message) onInsert, {
    void Function(Map<String, dynamic> message)? onUpdate,
  }) {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    var channel = client.channel('channel_$channelId');
    channel = channel
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
            if (payload.newRecord['thread_id'] != null) return;
            onInsert(payload.newRecord);
          },
        );
    if (onUpdate != null) {
      channel = channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'channel_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'channel_id',
          value: channelId,
        ),
        callback: (payload) {
          if (payload.newRecord['thread_id'] != null) return;
          onUpdate(payload.newRecord);
        },
      );
    }
    return channel.subscribe();
  }

  // F-02: Reactions
  static Future<void> toggleReaction({
    required String messageId,
    required String userId,
    required String emoji,
    required bool add,
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is not configured; reaction was not saved.');
    }
    final client = getSupabase();
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
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is not configured; edit was not saved.');
    }
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
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is not configured; delete was not saved.');
    }
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
