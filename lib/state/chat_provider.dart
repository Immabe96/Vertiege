import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/crash_reporter.dart';
import '../services/media_service.dart';
import '../services/mutation_outbox_service.dart';
import '../services/storage_service.dart';
import '../services/typing_service.dart';
import '../utils/chat_unread.dart';
import '../utils/id_generator.dart';
import '../utils/rate_limiter.dart';
import 'resident_provider.dart';

class ChatState {
  final List<Map<String, dynamic>> dmRooms;
  final Map<String, List<ChannelMessage>> dmMessages;
  final Map<String, bool> dmHasMore;
  final Map<String, bool> dmLoadingOlder;
  final Map<String, List<ChannelMessage>> channelMessages;
  final Map<String, DateTime> channelReads;
  final Map<String, DateTime> channelLatestMessageTimes;
  final Map<String, Set<String>> typingUsers;
  final bool isLoadingRooms;
  final String? roomsLoadError;

  const ChatState({
    this.dmRooms = const [],
    this.dmMessages = const {},
    this.dmHasMore = const {},
    this.dmLoadingOlder = const {},
    this.channelMessages = const {},
    this.channelReads = const {},
    this.channelLatestMessageTimes = const {},
    this.typingUsers = const {},
    this.isLoadingRooms = false,
    this.roomsLoadError,
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? dmRooms,
    Map<String, List<ChannelMessage>>? dmMessages,
    Map<String, bool>? dmHasMore,
    Map<String, bool>? dmLoadingOlder,
    Map<String, List<ChannelMessage>>? channelMessages,
    Map<String, DateTime>? channelReads,
    Map<String, DateTime>? channelLatestMessageTimes,
    Map<String, Set<String>>? typingUsers,
    bool? isLoadingRooms,
    String? roomsLoadError,
    bool clearRoomsLoadError = false,
  }) => ChatState(
    dmRooms: dmRooms ?? this.dmRooms,
    dmMessages: dmMessages ?? this.dmMessages,
    dmHasMore: dmHasMore ?? this.dmHasMore,
    dmLoadingOlder: dmLoadingOlder ?? this.dmLoadingOlder,
    channelMessages: channelMessages ?? this.channelMessages,
    channelReads: channelReads ?? this.channelReads,
    channelLatestMessageTimes:
        channelLatestMessageTimes ?? this.channelLatestMessageTimes,
    typingUsers: typingUsers ?? this.typingUsers,
    isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
    roomsLoadError:
        clearRoomsLoadError ? null : (roomsLoadError ?? this.roomsLoadError),
  );
}

class ChatNotifier extends Notifier<ChatState> {
  final Map<String, RealtimeChannel> _subscriptions = {};
  final Map<String, RealtimeChannel> _dmSubscriptions = {};
  final Map<String, void Function(String, String, bool)> _typingListeners = {};
  RealtimeChannel? _dmRoomsListChannel;
  String? _dmRoomsListSubscribedFor;
  static final DateTime _emptyChannelActivity =
      DateTime.fromMillisecondsSinceEpoch(0);
  static const int _dmFetchLimit = 100;
  static const int _dmMemoryCap = 300;
  static const int _dmPersistCap = 200;

  @override
  ChatState build() {
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (previous == null) return;
      unawaited(_persistMessages(next));
    });
    unawaited(_loadCachedMessages());
    ref.onDispose(_dispose);
    return const ChatState();
  }

  void _dispose() {
    for (final roomId in _typingListeners.keys.toList()) {
      unsubscribeFromTyping(roomId);
    }
    TypingService.dispose();
    unsubscribeAll();
  }

  // ── Typing indicators ──────────────────────────────────

  void startTyping(String roomId, String userId) {
    TypingService.startTyping(roomId, userId);
  }

  void stopTyping(String roomId, String userId) {
    TypingService.stopTyping(roomId, userId);
  }

  List<String> getTypingUsers(String roomId, {String? excludeUserId}) {
    return TypingService.getTypingUsers(roomId, excludeUserId: excludeUserId);
  }

  void subscribeToTyping(String roomId) {
    final existing = _typingListeners.remove(roomId);
    if (existing != null) {
      TypingService.removeListener(existing);
    }

    void handler(String rId, String userId, bool isTyping) {
      if (rId != roomId) return;
      final current = Map<String, Set<String>>.from(state.typingUsers);
      current.putIfAbsent(roomId, () => {});
      if (isTyping) {
        current[roomId]!.add(userId);
      } else {
        current[roomId]!.remove(userId);
      }
      if (current[roomId]!.isEmpty) {
        current.remove(roomId);
      }
      state = state.copyWith(typingUsers: current);
    }

    _typingListeners[roomId] = handler;
    TypingService.addListener(handler);
    TypingService.subscribe(roomId);
  }

  void unsubscribeFromTyping(String roomId) {
    final handler = _typingListeners.remove(roomId);
    if (handler != null) {
      TypingService.removeListener(handler);
    }
    TypingService.unsubscribe(roomId);

    final current = Map<String, Set<String>>.from(state.typingUsers);
    current.remove(roomId);
    state = state.copyWith(typingUsers: current);
  }

  Future<void> loadDmRooms(String residentId) async {
    if (state.isLoadingRooms) return;
    state = state.copyWith(isLoadingRooms: true, clearRoomsLoadError: true);

    try {
      await _replayQueuedChatMutations();
      final rooms = await ChatService.getRooms(
        residentId,
      ).timeout(const Duration(seconds: 5));
      state = state.copyWith(
        dmRooms: rooms,
        isLoadingRooms: false,
        clearRoomsLoadError: true,
      );
      for (final room in rooms) {
        final roomId = room['id'] as String?;
        if (roomId != null) subscribeToDm(roomId);
      }
      _subscribeToDmRoomsList(residentId);
    } catch (_) {
      state = state.copyWith(
        isLoadingRooms: false,
        roomsLoadError: 'Could not load conversations. Pull to refresh.',
      );
    }
  }

  List<ChannelMessage> dmMessagesFor(String roomId) =>
      _filterExpired(state.dmMessages[roomId] ?? []);

  bool dmHasMoreFor(String roomId) => state.dmHasMore[roomId] ?? false;

  bool dmLoadingOlderFor(String roomId) => state.dmLoadingOlder[roomId] ?? false;

  List<ChannelMessage> _capDmRoomMessages(List<ChannelMessage> messages) {
    if (messages.length <= _dmMemoryCap) return messages;
    return messages.sublist(messages.length - _dmMemoryCap);
  }

  List<ChannelMessage> _mergeDmMessages(
    List<ChannelMessage> older,
    List<ChannelMessage> existing,
  ) {
    final seen = <String>{};
    final merged = <ChannelMessage>[];
    for (final message in [...older, ...existing]) {
      if (seen.add(message.id)) merged.add(message);
    }
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return _capDmRoomMessages(merged);
  }

  Future<void> loadDmMessages(String roomId, {bool force = false}) async {
    if (!force && state.dmMessages.containsKey(roomId)) return;
    await _replayQueuedChatMutations();
    final msgs = await ChatService.getMessages(roomId, limit: _dmFetchLimit);
    final parsed = _capDmRoomMessages(_toChannelMessages(msgs));
    state = state.copyWith(
      dmMessages: {...state.dmMessages, roomId: parsed},
      dmHasMore: {...state.dmHasMore, roomId: msgs.length >= _dmFetchLimit},
      dmLoadingOlder: {...state.dmLoadingOlder, roomId: false},
    );
  }

  Future<void> loadOlderDmMessages(String roomId) async {
    if (state.dmLoadingOlder[roomId] == true) return;
    if (state.dmHasMore[roomId] != true) return;

    final existing = state.dmMessages[roomId] ?? [];
    if (existing.isEmpty) return;

    final oldest = existing.first;
    if (oldest.createdAt <= 0) return;

    state = state.copyWith(
      dmLoadingOlder: {...state.dmLoadingOlder, roomId: true},
    );

    try {
      final msgs = await ChatService.getMessages(
        roomId,
        limit: _dmFetchLimit,
        before: DateTime.fromMillisecondsSinceEpoch(oldest.createdAt),
      );
      final older = _toChannelMessages(msgs);
      state = state.copyWith(
        dmMessages: {
          ...state.dmMessages,
          roomId: _mergeDmMessages(older, existing),
        },
        dmHasMore: {...state.dmHasMore, roomId: msgs.length >= _dmFetchLimit},
        dmLoadingOlder: {...state.dmLoadingOlder, roomId: false},
      );
    } catch (_) {
      state = state.copyWith(
        dmLoadingOlder: {...state.dmLoadingOlder, roomId: false},
      );
    }
  }

  List<ChannelMessage> _filterExpired(List<ChannelMessage> messages) {
    final now = DateTime.now();
    return messages.where((m) {
      if (m.autoDeleteAfterSeconds == null) return true;
      final created = DateTime.fromMillisecondsSinceEpoch(m.createdAt);
      return created
          .add(Duration(seconds: m.autoDeleteAfterSeconds!))
          .isAfter(now);
    }).toList();
  }

  static const String _autoDeletePrefsPrefix = 'auto_delete_';

  Future<int?> getAutoDeleteForRoom(String roomId) async {
    final raw = await StorageService.getString(
      '$_autoDeletePrefsPrefix$roomId',
    );
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  Future<void> setAutoDeleteForRoom(String roomId, int? seconds) async {
    if (seconds == null) {
      await StorageService.remove('$_autoDeletePrefsPrefix$roomId');
    } else {
      await StorageService.setString(
        '$_autoDeletePrefsPrefix$roomId',
        seconds.toString(),
      );
    }
  }

  Future<void> sendDmMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    String? imageUrl,
    int? autoDeleteAfterSeconds,
  }) async {
    if (!RateLimiter.canProceed('message_$roomId', maxCalls: 3)) return;

    CrashReporter.instance.log(
      'chat sendDmMessage roomId=$roomId hasImage=${imageUrl != null}',
    );

    final localImagePath =
        imageUrl != null && !imageUrl.startsWith('http') ? imageUrl : null;

    final msg = ChannelMessage(
      id: generateId(),
      channelId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      autoDeleteAfterSeconds: autoDeleteAfterSeconds,
    );

    final existing = state.dmMessages[roomId] ?? [];
    state = state.copyWith(
      dmMessages: {
        ...state.dmMessages,
        roomId: _capDmRoomMessages([...existing, msg]),
      },
    );
    _patchDmRoomsPreview(roomId, msg);

    if (localImagePath != null) {
      unawaited(
        _persistDmMessage(
          msg: msg,
          roomId: roomId,
          senderId: senderId,
          senderName: senderName,
          senderAvatar: senderAvatar,
          content: content,
          localImagePath: localImagePath,
          autoDeleteAfterSeconds: autoDeleteAfterSeconds,
        ),
      );
      return;
    }

    await _persistDmMessage(
      msg: msg,
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      imageUrl: imageUrl,
      autoDeleteAfterSeconds: autoDeleteAfterSeconds,
    );
  }

  Future<void> _persistDmMessage({
    required ChannelMessage msg,
    required String roomId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    String? imageUrl,
    String? localImagePath,
    int? autoDeleteAfterSeconds,
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToSenderName,
    String? replyToContent,
  }) async {
    String? durableImageUrl = imageUrl;
    if (localImagePath != null) {
      try {
        durableImageUrl = await MediaService.uploadPostImage(
          localImagePath,
          senderId,
        );
      } catch (_) {
        _markDmMessageFailed(roomId, msg);
        return;
      }
    }

    try {
      await ChatService.sendMessage(
        messageId: msg.id,
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content,
        imageUrl: durableImageUrl,
        autoDeleteAfterSeconds: autoDeleteAfterSeconds,
        replyToMessageId: replyToMessageId,
        replyToSenderId: replyToSenderId,
        replyToSenderName: replyToSenderName,
        replyToContent: replyToContent,
      );
      ref.read(residentProvider.notifier).awardActivityXp('comment', 3);
    } catch (_) {
      await MutationOutboxService.enqueue('chat.message', {
        'roomId': roomId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'content': content,
        'imageUrl': durableImageUrl,
        'autoDeleteAfterSeconds': autoDeleteAfterSeconds,
        'messageId': msg.id,
        if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
        if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
        if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
        if (replyToContent != null) 'replyToContent': replyToContent,
      });
      _markDmMessageFailed(roomId, msg);
    }
  }

  void _markDmMessageFailed(String roomId, ChannelMessage msg) {
    final failedMsg = msg.copyWith(content: 'Failed to send - tap to retry');
    final updated = state.dmMessages[roomId]
        ?.map((m) => m.id == msg.id ? failedMsg : m)
        .toList();
    state = state.copyWith(
      dmMessages: {...state.dmMessages, roomId: updated ?? []},
    );
  }

  // ── Shared realtime subscription helper ──────────────────

  static ChannelMessage _parseRealtimeMessage(
    Map<String, dynamic> data,
    String roomId,
  ) {
    return ChannelMessage(
      id: data['id'] ?? '',
      channelId: roomId,
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? '',
      senderAvatar: data['sender_avatar'],
      content: data['content'] ?? '',
      imageUrl: data['image_url'],
      isPinned: data['is_pinned'] ?? false,
      threadId: data['thread_id'],
      threadCount: data['thread_count'] ?? 0,
      isThreadStarter: data['is_thread_starter'] ?? false,
      createdAt:
          DateTime.tryParse(data['created_at'] ?? '')?.millisecondsSinceEpoch ??
          0,
      replyToMessageId: data['reply_to_message_id'],
      replyToSenderId: data['reply_to_sender_id'],
      replyToSenderName: data['reply_to_sender_name'],
      replyToContent: data['reply_to_content'],
      reactions: data['reactions'] != null
          ? (data['reactions'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            )
          : {},
      isEdited: data['is_edited'] ?? false,
      editedAt: data['edited_at'],
      isDeleted: data['is_deleted'] ?? false,
      autoDeleteAfterSeconds: data['auto_delete_after_seconds'],
    );
  }

  void _subscribeToRealtime({
    required String roomId,
    required Map<String, RealtimeChannel> subscriptions,
    required Map<String, List<ChannelMessage>> Function() getMessageMap,
    required ChatState Function(Map<String, List<ChannelMessage>> updatedMap)
    updateState,
    required RealtimeChannel? Function(
      String,
      void Function(Map<String, dynamic>),
    )
    subscribe,
    bool trackChannelActivity = false,
    void Function(ChannelMessage message)? onMessageInserted,
  }) {
    if (subscriptions.containsKey(roomId)) return;
    final channel = subscribe(roomId, (data) {
      final msg = _parseRealtimeMessage(data, roomId);
      CrashReporter.instance.log(
        'chat realtime receive roomId=$roomId messageId=${msg.id}',
      );
      final messages = getMessageMap();
      final existing = messages[roomId] ?? [];
      if (existing.any((m) => m.id == msg.id)) return;
      var nextState = updateState({
        ...messages,
        roomId: [...existing, msg],
      });
      if (trackChannelActivity && msg.createdAt > 0) {
        nextState = nextState.copyWith(
          channelLatestMessageTimes: _mergeLatestMessageTime(
            nextState.channelLatestMessageTimes,
            roomId,
            DateTime.fromMillisecondsSinceEpoch(msg.createdAt),
          ),
        );
      }
      state = nextState;
      onMessageInserted?.call(msg);
    });
    if (channel != null) {
      subscriptions[roomId] = channel;
    }
  }

  void _subscribeToDmRoomsList(String residentId) {
    if (_dmRoomsListSubscribedFor == residentId && _dmRoomsListChannel != null) {
      return;
    }
    _dmRoomsListChannel?.unsubscribe();
    _dmRoomsListChannel = ChatService.subscribeToDmRoomListUpdates(
      residentId,
      _mergeDmRoomListUpdate,
    );
    _dmRoomsListSubscribedFor = residentId;
  }

  void _mergeDmRoomListUpdate(Map<String, dynamic> record) {
    final roomId = record['id'] as String?;
    if (roomId == null || state.dmRooms.isEmpty) return;

    final index = state.dmRooms.indexWhere((room) => room['id'] == roomId);
    if (index == -1) return;

    final existing = state.dmRooms[index];
    final lastMessage = record['last_message'];
    final lastMessageAt = record['last_message_at'];
    if (lastMessage == null && lastMessageAt == null) return;

    final merged = {
      ...existing,
      if (lastMessage != null) 'last_message': lastMessage,
      if (lastMessageAt != null) 'last_message_at': lastMessageAt,
    };

    final updated = List<Map<String, dynamic>>.from(state.dmRooms);
    updated[index] = merged;
    updated.sort((a, b) {
      final atA = DateTime.tryParse(a['last_message_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final atB = DateTime.tryParse(b['last_message_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return atB.compareTo(atA);
    });
    state = state.copyWith(dmRooms: updated);
  }

  /// Keeps DM inbox preview + sort in sync without refetching all rooms.
  void _patchDmRoomsPreview(String roomId, ChannelMessage msg) {
    if (state.dmRooms.isEmpty) return;
    final preview = msg.content.trim().isNotEmpty
        ? msg.content.trim()
        : (msg.imageUrl != null ? 'Image' : '');
    final at = msg.createdAt > 0
        ? DateTime.fromMillisecondsSinceEpoch(msg.createdAt)
        : DateTime.now();
    final updated = state.dmRooms.map((room) {
      if (room['id'] != roomId) return room;
      return {
        ...room,
        'last_message': preview,
        'last_message_at': at.toIso8601String(),
      };
    }).toList();
    updated.sort((a, b) {
      final atA = DateTime.tryParse(a['last_message_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final atB = DateTime.tryParse(b['last_message_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return atB.compareTo(atA);
    });
    state = state.copyWith(dmRooms: updated);
  }

  void subscribeToDm(String roomId) {
    _subscribeToRealtime(
      roomId: roomId,
      subscriptions: _dmSubscriptions,
      getMessageMap: () => state.dmMessages,
      updateState: (updated) {
        final capped = updated.map(
          (key, value) => MapEntry(key, _capDmRoomMessages(value)),
        );
        return state.copyWith(dmMessages: capped);
      },
      subscribe: ChatService.subscribeToMessages,
      onMessageInserted: (msg) => _patchDmRoomsPreview(roomId, msg),
    );
  }

  /// Intentionally no per-room unsubscribe — inbox realtime stays active until sign-out.
  void unsubscribeFromDm(String roomId) {
    // Reserved for tests or future selective teardown.
  }

  List<ChannelMessage> channelMessagesFor(String channelId) =>
      state.channelMessages[channelId] ?? [];

  List<ChannelMessage> pinnedMessagesFor(String channelId) {
    final messages = state.channelMessages[channelId] ?? [];
    return messages.where((m) => m.isPinned).toList();
  }

  Future<void> togglePin({
    required String channelId,
    required String messageId,
    required bool isPinned,
  }) async {
    final messages = state.channelMessages[channelId];
    if (messages == null) return;
    final updated = messages.map((m) {
      if (m.id == messageId) return m.copyWith(isPinned: isPinned);
      return m;
    }).toList();
    state = state.copyWith(
      channelMessages: {...state.channelMessages, channelId: updated},
    );
    await ChatService.pinMessage(messageId: messageId, isPinned: isPinned);
  }

  Future<void> loadChannelMessages(
    String channelId, {
    bool force = false,
  }) async {
    if (!force && state.channelMessages.containsKey(channelId)) return;
    await _replayQueuedChatMutations();
    final msgs = await ChatService.getChannelMessages(channelId);
    state = state.copyWith(
      channelMessages: {
        ...state.channelMessages,
        channelId: _toChannelMessages(msgs),
      },
    );
  }

  Future<void> sendChannelMessage({
    required String worldId,
    required String channelId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    String? imageUrl,
  }) async {
    if (!RateLimiter.canProceed('message_$channelId', maxCalls: 3)) return;

    String? durableImageUrl = imageUrl;
    if (durableImageUrl != null && !durableImageUrl.startsWith('http')) {
      durableImageUrl = await MediaService.uploadPostImage(
        durableImageUrl,
        senderId,
      );
    }

    final msg = ChannelMessage(
      id: generateId(),
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      imageUrl: durableImageUrl ?? imageUrl,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final existing = state.channelMessages[channelId] ?? [];
    final allMessages = [...existing, msg];
    state = state.copyWith(
      channelMessages: {...state.channelMessages, channelId: allMessages},
      channelLatestMessageTimes: _mergeLatestMessageTime(
        state.channelLatestMessageTimes,
        channelId,
        DateTime.fromMillisecondsSinceEpoch(msg.createdAt),
      ),
    );

    try {
      final inserted = await ChatService.sendChannelMessage(
        messageId: msg.id,
        channelId: channelId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        worldId: worldId,
        content: content,
        imageUrl: durableImageUrl,
      );
      final confirmed = _toChannelMessages([inserted]).first;
      final current = state.channelMessages[channelId] ?? const [];
      state = state.copyWith(
        channelMessages: {
          ...state.channelMessages,
          channelId: current
              .map((m) => m.id == msg.id ? confirmed : m)
              .toList(),
        },
      );
      ref.read(residentProvider.notifier).awardActivityXp('comment', 3);
      await markChannelRead(channelId: channelId, residentId: senderId);
    } catch (_) {
      await MutationOutboxService.enqueue('channel.message', {
        'worldId': worldId,
        'channelId': channelId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'content': content,
        'imageUrl': durableImageUrl,
        'messageId': msg.id,
      });
      final failedMsg = msg.copyWith(content: 'Failed to send - tap to retry');
      final updated = allMessages
          .map((m) => m.id == msg.id ? failedMsg : m)
          .toList();
      state = state.copyWith(
        channelMessages: {...state.channelMessages, channelId: updated},
        channelLatestMessageTimes: _mergeLatestMessageTime(
          state.channelLatestMessageTimes,
          channelId,
          latestMessageTime(updated) ?? _emptyChannelActivity,
          replace: true,
        ),
      );
    }
  }

  void subscribeToChannel(String channelId) {
    _subscribeToRealtime(
      roomId: channelId,
      subscriptions: _subscriptions,
      getMessageMap: () => state.channelMessages,
      updateState: (updated) => state.copyWith(channelMessages: updated),
      subscribe: ChatService.subscribeToChannelMessages,
      trackChannelActivity: true,
    );
  }

  void unsubscribeFromChannel(String channelId) {
    _subscriptions[channelId]?.unsubscribe();
    _subscriptions.remove(channelId);
  }

  // ── Channel read tracking ──────────────────────────────

  Future<void> loadChannelReads(String residentId) async {
    final reads = await ChatService.getChannelReads(residentId);
    state = state.copyWith(channelReads: reads);
  }

  Future<void> loadChannelActivity(
    List<String> channelIds, {
    bool force = false,
  }) async {
    final ids = channelIds.toSet().where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return;
    final toLoad = force
        ? ids
        : ids
              .where((id) => !state.channelLatestMessageTimes.containsKey(id))
              .toList();
    if (toLoad.isEmpty) return;

    final latest = await ChatService.getLatestChannelMessageTimestamps(toLoad);
    final merged = {...state.channelLatestMessageTimes};
    for (final id in toLoad) {
      merged[id] = latest[id] ?? _emptyChannelActivity;
    }
    state = state.copyWith(channelLatestMessageTimes: merged);
  }

  Future<void> markChannelRead({
    required String channelId,
    required String residentId,
  }) async {
    final now = DateTime.now();
    state = state.copyWith(
      channelReads: {...state.channelReads, channelId: now},
    );
    await ChatService.markChannelRead(
      channelId: channelId,
      residentId: residentId,
    );
  }

  // ── Threads ────────────────────────────────────────────

  Future<void> loadThreadMessages(String threadId) async {
    final msgs = await ChatService.getThreadMessages(threadId);
    state = state.copyWith(
      channelMessages: {
        ...state.channelMessages,
        threadId: _toChannelMessages(msgs),
      },
    );
  }

  Future<void> sendThreadReply({
    required String channelId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String worldId,
    required String content,
    required String threadId,
  }) async {
    final msg = ChannelMessage(
      id: generateId(),
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      threadId: threadId,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final existing = state.channelMessages[threadId] ?? [];
    state = state.copyWith(
      channelMessages: {
        ...state.channelMessages,
        threadId: [...existing, msg],
      },
    );
    try {
      await ChatService.sendThreadReply(
        messageId: msg.id,
        channelId: channelId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        worldId: worldId,
        content: content,
        threadId: threadId,
      );
    } catch (_) {
      final reverted = (state.channelMessages[threadId] ?? [])
          .where((m) => m.id != msg.id)
          .toList();
      state = state.copyWith(
        channelMessages: {...state.channelMessages, threadId: reverted},
      );
      rethrow;
    }
  }

  int unreadCount(String channelId, {String? currentUserId}) {
    final messages = state.channelMessages[channelId] ?? [];
    final lastRead = state.channelReads[channelId];
    final latest = state.channelLatestMessageTimes[channelId];
    return countUnreadMessages(
      loadedMessages: messages,
      lastReadAt: lastRead,
      latestMessageAt: latest == _emptyChannelActivity ? null : latest,
      excludeSenderId: currentUserId,
    );
  }

  bool hasUnread(String channelId, {String? currentUserId}) {
    final messages = state.channelMessages[channelId] ?? [];
    final lastRead = state.channelReads[channelId];
    final latest = state.channelLatestMessageTimes[channelId];
    return hasUnreadMessages(
      loadedMessages: messages,
      lastReadAt: lastRead,
      latestMessageAt: latest == _emptyChannelActivity ? null : latest,
      excludeSenderId: currentUserId,
    );
  }

  void unsubscribeAll() {
    _dmRoomsListChannel?.unsubscribe();
    _dmRoomsListChannel = null;
    _dmRoomsListSubscribedFor = null;
    for (final s in _dmSubscriptions.values) {
      s.unsubscribe();
    }
    _dmSubscriptions.clear();
    for (final s in _subscriptions.values) {
      s.unsubscribe();
    }
    _subscriptions.clear();
  }

  // F-01: Reply-to-message
  Future<void> sendDmReply({
    required String roomId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    String? imageUrl,
    required String replyToMessageId,
    required String replyToSenderId,
    required String replyToSenderName,
    required String replyToContent,
  }) async {
    if (!RateLimiter.canProceed('message_$roomId', maxCalls: 3)) return;

    CrashReporter.instance.log(
      'chat sendDmReply roomId=$roomId hasImage=${imageUrl != null}',
    );

    final localImagePath =
        imageUrl != null && !imageUrl.startsWith('http') ? imageUrl : null;

    final msg = ChannelMessage(
      id: generateId(),
      channelId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      imageUrl: imageUrl,
      replyToMessageId: replyToMessageId,
      replyToSenderId: replyToSenderId,
      replyToSenderName: replyToSenderName,
      replyToContent: replyToContent,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final existing = state.dmMessages[roomId] ?? [];
    state = state.copyWith(
      dmMessages: {
        ...state.dmMessages,
        roomId: _capDmRoomMessages([...existing, msg]),
      },
    );
    _patchDmRoomsPreview(roomId, msg);

    if (localImagePath != null) {
      unawaited(
        _persistDmMessage(
          msg: msg,
          roomId: roomId,
          senderId: senderId,
          senderName: senderName,
          senderAvatar: senderAvatar,
          content: content,
          localImagePath: localImagePath,
          replyToMessageId: replyToMessageId,
          replyToSenderId: replyToSenderId,
          replyToSenderName: replyToSenderName,
          replyToContent: replyToContent,
        ),
      );
      return;
    }

    try {
      await ChatService.sendMessage(
        messageId: msg.id,
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: content,
        imageUrl: imageUrl,
        replyToMessageId: replyToMessageId,
        replyToSenderId: replyToSenderId,
        replyToSenderName: replyToSenderName,
        replyToContent: replyToContent,
      );
      ref.read(residentProvider.notifier).awardActivityXp('comment', 3);
    } catch (_) {
      _markDmMessageFailed(roomId, msg);
      rethrow;
    }
  }

  // F-02: Message reactions
  Future<void> toggleReaction({
    required String roomId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final messages = state.dmMessages[roomId] ?? [];
    final msgIndex = messages.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;

    final msg = messages[msgIndex];
    final currentReactions = Map<String, List<String>>.from(msg.reactions);
    final users = List<String>.from(currentReactions[emoji] ?? []);

    if (users.contains(userId)) {
      users.remove(userId);
      if (users.isEmpty) {
        currentReactions.remove(emoji);
      } else {
        currentReactions[emoji] = users;
      }
    } else {
      currentReactions[emoji] = [...users, userId];
    }

    final updatedMsg = msg.copyWith(reactions: currentReactions);
    final updatedMessages = List<ChannelMessage>.from(messages);
    updatedMessages[msgIndex] = updatedMsg;

    state = state.copyWith(
      dmMessages: {...state.dmMessages, roomId: updatedMessages},
    );

    try {
      await ChatService.toggleReaction(
        messageId: messageId,
        userId: userId,
        emoji: emoji,
        add: users.contains(userId),
      );
    } catch (_) {
      final revertedMessages = List<ChannelMessage>.from(messages);
      revertedMessages[msgIndex] = msg;
      state = state.copyWith(
        dmMessages: {...state.dmMessages, roomId: revertedMessages},
      );
      rethrow;
    }
  }

  // F-03: Message edit
  Future<void> editMessage({
    required String roomId,
    required String messageId,
    required String newContent,
  }) async {
    final messages = state.dmMessages[roomId] ?? [];
    final msgIndex = messages.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;

    final msg = messages[msgIndex];
    final updatedMsg = msg.copyWith(
      content: newContent,
      isEdited: true,
      editedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final updatedMessages = List<ChannelMessage>.from(messages);
    updatedMessages[msgIndex] = updatedMsg;

    state = state.copyWith(
      dmMessages: {...state.dmMessages, roomId: updatedMessages},
    );

    try {
      await ChatService.editMessage(
        messageId: messageId,
        newContent: newContent,
      );
    } catch (_) {
      final revertedMessages = List<ChannelMessage>.from(messages);
      revertedMessages[msgIndex] = msg;
      state = state.copyWith(
        dmMessages: {...state.dmMessages, roomId: revertedMessages},
      );
      rethrow;
    }
  }

  // F-03: Message delete
  Future<void> deleteMessage({
    required String roomId,
    required String messageId,
  }) async {
    final messages = state.dmMessages[roomId] ?? [];
    final msgIndex = messages.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) return;

    final msg = messages[msgIndex];
    final updatedMsg = msg.copyWith(
      content: 'This message was deleted',
      isDeleted: true,
    );
    final updatedMessages = List<ChannelMessage>.from(messages);
    updatedMessages[msgIndex] = updatedMsg;

    state = state.copyWith(
      dmMessages: {...state.dmMessages, roomId: updatedMessages},
    );

    try {
      await ChatService.deleteMessage(messageId: messageId);
    } catch (_) {
      final revertedMessages = List<ChannelMessage>.from(messages);
      revertedMessages[msgIndex] = msg;
      state = state.copyWith(
        dmMessages: {...state.dmMessages, roomId: revertedMessages},
      );
      rethrow;
    }
  }

  List<ChannelMessage> _toChannelMessages(List<Map<String, dynamic>> raw) => raw
      .map(
        (e) => ChannelMessage(
          id: e['id'] ?? '',
          channelId: e['room_id'] ?? e['channel_id'] ?? '',
          senderId: e['sender_id'] ?? '',
          senderName: e['sender_name'] ?? '',
          senderAvatar: e['sender_avatar'],
          content: e['content'] ?? '',
          imageUrl: e['image_url'],
          isPinned: e['is_pinned'] ?? false,
          threadId: e['thread_id'],
          threadCount: e['thread_count'] ?? 0,
          isThreadStarter: e['is_thread_starter'] ?? false,
          createdAt:
              DateTime.tryParse(
                e['created_at'] ?? '',
              )?.millisecondsSinceEpoch ??
              0,
          replyToMessageId: e['reply_to_message_id'],
          replyToSenderId: e['reply_to_sender_id'],
          replyToSenderName: e['reply_to_sender_name'],
          replyToContent: e['reply_to_content'],
          reactions: e['reactions'] != null
              ? (e['reactions'] as Map<String, dynamic>).map(
                  (key, value) => MapEntry(key, List<String>.from(value)),
                )
              : {},
          isEdited: e['is_edited'] ?? false,
          editedAt: e['edited_at'],
          isDeleted: e['is_deleted'] ?? false,
          autoDeleteAfterSeconds: e['auto_delete_after_seconds'],
        ),
      )
      .toList();

  Future<void> _replayQueuedChatMutations() async {
    await MutationOutboxService.replayWhere(
      (mutation) =>
          mutation.type == 'chat.message' || mutation.type == 'channel.message',
      (mutation) async {
        switch (mutation.type) {
          case 'chat.message':
            final payload = mutation.payload;
            await ChatService.sendMessage(
              messageId: payload['messageId'] as String,
              roomId: payload['roomId'] as String,
              senderId: payload['senderId'] as String,
              senderName: payload['senderName'] as String,
              senderAvatar: payload['senderAvatar'] as String?,
              content: payload['content'] as String,
              imageUrl: payload['imageUrl'] as String?,
              autoDeleteAfterSeconds: payload['autoDeleteAfterSeconds'] as int?,
            );
            return;
          case 'channel.message':
            final payload = mutation.payload;
            await ChatService.sendChannelMessage(
              messageId: payload['messageId'] as String,
              worldId: payload['worldId'] as String,
              channelId: payload['channelId'] as String,
              senderId: payload['senderId'] as String,
              senderName: payload['senderName'] as String,
              senderAvatar: payload['senderAvatar'] as String?,
              content: payload['content'] as String,
              imageUrl: payload['imageUrl'] as String?,
            );
            return;
          default:
            return;
        }
      },
    );
  }

  Map<String, DateTime> _mergeLatestMessageTime(
    Map<String, DateTime> existing,
    String channelId,
    DateTime createdAt, {
    bool replace = false,
  }) {
    if (createdAt == _emptyChannelActivity) {
      return {...existing, channelId: createdAt};
    }
    final current = existing[channelId];
    if (!replace && current != null && current.isAfter(createdAt)) {
      return existing;
    }
    return {...existing, channelId: createdAt};
  }

  Future<void> _loadCachedMessages() async {
    final raw = await StorageService.getString(StorageService.chatMessagesKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      state = state.copyWith(
        dmMessages: _decodeMessageMap(data['dmMessages']),
        channelMessages: _decodeMessageMap(data['channelMessages']),
        channelReads: _decodeDateMap(data['channelReads']),
        channelLatestMessageTimes: _decodeDateMap(
          data['channelLatestMessageTimes'],
        ),
      );
    } catch (_) {}
  }

  Future<void> _persistMessages(ChatState snapshot) async {
    final payload = jsonEncode({
      'dmMessages': _encodeMessageMap(
        snapshot.dmMessages,
        maxPerRoom: _dmPersistCap,
      ),
      'channelMessages': _encodeMessageMap(snapshot.channelMessages),
      'channelReads': _encodeDateMap(snapshot.channelReads),
      'channelLatestMessageTimes': _encodeDateMap(
        snapshot.channelLatestMessageTimes,
      ),
    });
    await StorageService.setStringDebounced(
      StorageService.chatMessagesKey,
      payload,
    );
  }

  Map<String, List<ChannelMessage>> _decodeMessageMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((key, rawList) {
      final messages = rawList is List
          ? rawList
                .whereType<Map>()
                .map(
                  (item) =>
                      ChannelMessage.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const <ChannelMessage>[];
      return MapEntry(key.toString(), messages);
    });
  }

  Map<String, dynamic> _encodeMessageMap(
    Map<String, List<ChannelMessage>> messages, {
    int? maxPerRoom,
  }) =>
      messages.map((key, value) {
        final capped = maxPerRoom != null && value.length > maxPerRoom
            ? value.sublist(value.length - maxPerRoom)
            : value;
        return MapEntry(
          key,
          capped.map((message) => message.toJson()).toList(),
        );
      });

  Map<String, DateTime> _decodeDateMap(dynamic value) {
    if (value is! Map) return const {};
    final result = <String, DateTime>{};
    for (final entry in value.entries) {
      final parsed = DateTime.tryParse(entry.value?.toString() ?? '');
      if (parsed != null) result[entry.key.toString()] = parsed;
    }
    return result;
  }

  Map<String, String> _encodeDateMap(Map<String, DateTime> dates) =>
      dates.map((key, value) => MapEntry(key, value.toIso8601String()));

  void clearForSignOut() {
    unsubscribeAll();
    state = const ChatState();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

/// Narrow watch for a single DM thread (avoids rebuilding on unrelated rooms).
final dmRoomMessagesProvider = Provider.family<List<ChannelMessage>, String>((
  ref,
  roomId,
) {
  ref.watch(chatProvider.select((s) => s.dmMessages[roomId]));
  return ref.read(chatProvider.notifier).dmMessagesFor(roomId);
});
