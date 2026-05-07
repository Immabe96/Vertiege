import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../utils/id_generator.dart';

class ChatState {
  final List<Map<String, dynamic>> dmRooms;
  final Map<String, List<ChannelMessage>> dmMessages;
  final Map<String, List<ChannelMessage>> channelMessages;
  final bool isLoadingRooms;

  const ChatState({
    this.dmRooms = const [],
    this.dmMessages = const {},
    this.channelMessages = const {},
    this.isLoadingRooms = false,
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? dmRooms,
    Map<String, List<ChannelMessage>>? dmMessages,
    Map<String, List<ChannelMessage>>? channelMessages,
    bool? isLoadingRooms,
  }) =>
      ChatState(
        dmRooms: dmRooms ?? this.dmRooms,
        dmMessages: dmMessages ?? this.dmMessages,
        channelMessages: channelMessages ?? this.channelMessages,
        isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      );
}

class ChatNotifier extends Notifier<ChatState> {
  final Map<String, RealtimeChannel> _subscriptions = {};
  final Map<String, RealtimeChannel> _dmSubscriptions = {};

  @override
  ChatState build() {
    ref.onDispose(_dispose);
    return const ChatState();
  }

  void _dispose() {
    unsubscribeAll();
  }

  Future<void> loadDmRooms(String residentId) async {
    if (state.isLoadingRooms) return;
    state = state.copyWith(isLoadingRooms: true);

    try {
      final rooms = await ChatService.getRooms(residentId)
          .timeout(const Duration(seconds: 5));
      state = state.copyWith(dmRooms: rooms, isLoadingRooms: false);
    } catch (_) {
      state = state.copyWith(isLoadingRooms: false);
    }
  }

  List<ChannelMessage> dmMessagesFor(String roomId) =>
      state.dmMessages[roomId] ?? [];

  Future<void> loadDmMessages(String roomId) async {
    if (state.dmMessages.containsKey(roomId)) return;
    final msgs = await ChatService.getMessages(roomId);
    state = state.copyWith(
      dmMessages: {...state.dmMessages, roomId: _toChannelMessages(msgs)},
    );
  }

  Future<void> sendDmMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    String? imageUrl,
  }) async {
    final msg = ChannelMessage(
      id: generateId(),
      channelId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final existing = state.dmMessages[roomId] ?? [];
    state = state.copyWith(
      dmMessages: {...state.dmMessages, roomId: [...existing, msg]},
    );

    await ChatService.sendMessage(
      roomId: roomId,
      senderId: senderId,
      content: content,
    );
  }

  // ── Shared realtime subscription helper ──────────────────

  static ChannelMessage _parseRealtimeMessage(Map<String, dynamic> data, String roomId) {
    return ChannelMessage(
      id: data['id'] ?? '',
      channelId: roomId,
      senderId: data['sender_id'] ?? '',
      senderName: data['sender_name'] ?? '',
      senderAvatar: data['sender_avatar'],
      content: data['content'] ?? '',
      imageUrl: data['image_url'],
      createdAt: DateTime.tryParse(data['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0,
    );
  }

  void _subscribeToRealtime({
    required String roomId,
    required Map<String, RealtimeChannel> subscriptions,
    required Map<String, List<ChannelMessage>> Function() getMessageMap,
    required ChatState Function(Map<String, List<ChannelMessage>> updatedMap) updateState,
    required RealtimeChannel? Function(String, void Function(Map<String, dynamic>)) subscribe,
  }) {
    if (subscriptions.containsKey(roomId)) return;
    final channel = subscribe(roomId, (data) {
      final msg = _parseRealtimeMessage(data, roomId);
      final messages = getMessageMap();
      final existing = messages[roomId] ?? [];
      if (existing.any((m) => m.id == msg.id)) return;
      state = updateState({...messages, roomId: [...existing, msg]});
    });
    if (channel != null) {
      subscriptions[roomId] = channel;
    }
  }

  void subscribeToDm(String roomId) {
    _subscribeToRealtime(
      roomId: roomId,
      subscriptions: _dmSubscriptions,
      getMessageMap: () => state.dmMessages,
      updateState: (updated) => state.copyWith(dmMessages: updated),
      subscribe: ChatService.subscribeToMessages,
    );
  }

  void unsubscribeFromDm(String roomId) {
    _dmSubscriptions[roomId]?.unsubscribe();
    _dmSubscriptions.remove(roomId);
  }

  List<ChannelMessage> channelMessagesFor(String channelId) =>
      state.channelMessages[channelId] ?? [];

  Future<void> loadChannelMessages(String channelId) async {
    if (state.channelMessages.containsKey(channelId)) return;
    final msgs = await ChatService.getChannelMessages(channelId);
    state = state.copyWith(
      channelMessages: {...state.channelMessages, channelId: _toChannelMessages(msgs)},
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
    final msg = ChannelMessage(
      id: generateId(),
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: content,
      imageUrl: imageUrl,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final existing = state.channelMessages[channelId] ?? [];
    state = state.copyWith(
      channelMessages: {...state.channelMessages, channelId: [...existing, msg]},
    );

    await ChatService.sendChannelMessage(
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      worldId: worldId,
      content: content,
    );
  }

  void subscribeToChannel(String channelId) {
    _subscribeToRealtime(
      roomId: channelId,
      subscriptions: _subscriptions,
      getMessageMap: () => state.channelMessages,
      updateState: (updated) => state.copyWith(channelMessages: updated),
      subscribe: ChatService.subscribeToChannelMessages,
    );
  }

  void unsubscribeFromChannel(String channelId) {
    _subscriptions[channelId]?.unsubscribe();
    _subscriptions.remove(channelId);
  }

  void unsubscribeAll() {
    for (final s in _dmSubscriptions.values) {
      s.unsubscribe();
    }
    _dmSubscriptions.clear();
    for (final s in _subscriptions.values) {
      s.unsubscribe();
    }
    _subscriptions.clear();
  }

  List<ChannelMessage> _toChannelMessages(List<Map<String, dynamic>> raw) =>
      raw.map((e) => ChannelMessage(
            id: e['id'] ?? '',
            channelId: e['room_id'] ?? e['channel_id'] ?? '',
            senderId: e['sender_id'] ?? '',
            senderName: e['sender_name'] ?? '',
            senderAvatar: e['sender_avatar'],
            content: e['content'] ?? '',
            imageUrl: e['image_url'],
            createdAt: DateTime.tryParse(e['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0,
          )).toList();
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
