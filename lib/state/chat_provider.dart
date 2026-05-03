import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

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

class ChatNotifier extends StateNotifier<ChatState> {
  final Map<String, RealtimeChannel> _subscriptions = {};
  final Map<String, RealtimeChannel> _dmSubscriptions = {};

  ChatNotifier() : super(const ChatState());

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  // --- DM rooms ---

  Future<void> loadDmRooms(String residentId) async {
    if (state.isLoadingRooms) return;
    state = state.copyWith(isLoadingRooms: true);

    final rooms = await ChatService.getRooms(residentId);
    state = state.copyWith(dmRooms: rooms, isLoadingRooms: false);
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
      id: 'dm_${DateTime.now().millisecondsSinceEpoch}_${senderId.hashCode}',
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

  void subscribeToDm(String roomId) {
    if (_dmSubscriptions.containsKey(roomId)) return;
    final channel = ChatService.subscribeToMessages(roomId, (data) {
      final msg = ChannelMessage(
        id: data['id'] ?? '',
        channelId: roomId,
        senderId: data['sender_id'] ?? '',
        senderName: data['sender_name'] ?? '',
        senderAvatar: data['sender_avatar'],
        content: data['content'] ?? '',
        imageUrl: data['image_url'],
        createdAt: DateTime.parse(data['created_at'] ?? '').millisecondsSinceEpoch,
      );
      final existing = state.dmMessages[roomId] ?? [];
      if (existing.any((m) => m.id == msg.id)) return;
      state = state.copyWith(
        dmMessages: {...state.dmMessages, roomId: [...existing, msg]},
      );
    });
    if (channel != null) {
      _dmSubscriptions[roomId] = channel;
    }
  }

  void unsubscribeFromDm(String roomId) {
    _dmSubscriptions[roomId]?.unsubscribe();
    _dmSubscriptions.remove(roomId);
  }

  // --- Channel messages ---

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
    required String channelId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String content,
    String? imageUrl,
  }) async {
    final msg = ChannelMessage(
      id: 'ch_${DateTime.now().millisecondsSinceEpoch}_${senderId.hashCode}',
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
      content: content,
    );
  }

  void subscribeToChannel(String channelId) {
    if (_subscriptions.containsKey(channelId)) return;
    final channel = ChatService.subscribeToChannelMessages(channelId, (data) {
      final msg = ChannelMessage(
        id: data['id'] ?? '',
        channelId: channelId,
        senderId: data['sender_id'] ?? '',
        senderName: data['sender_name'] ?? '',
        senderAvatar: data['sender_avatar'],
        content: data['content'] ?? '',
        imageUrl: data['image_url'],
        createdAt: DateTime.tryParse(data['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0,
      );
      final existing = state.channelMessages[channelId] ?? [];
      if (existing.any((m) => m.id == msg.id)) return;
      state = state.copyWith(
        channelMessages: {...state.channelMessages, channelId: [...existing, msg]},
      );
    });
    if (channel != null) {
      _subscriptions[channelId] = channel;
    }
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

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);
