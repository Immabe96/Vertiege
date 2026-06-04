import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'supabase.dart';
import 'crash_reporter.dart';

class VoiceService {
  static Room? _currentRoom;
  static StreamController<List<Participant>>? _participantsController;
  static final List<Participant> _participants = [];
  static bool _disposed = false;
  static bool _isDeafened = false;
  static VoidCallback? onDisconnected;

  static Stream<List<Participant>> get participantsStream {
    if (_disposed || _participantsController == null || _participantsController!.isClosed) {
      _participantsController = StreamController<List<Participant>>.broadcast();
      _disposed = false;
    }
    return _participantsController!.stream;
  }

  static List<Participant> get participants => List.unmodifiable(_participants);

  static bool get isConnected => _currentRoom != null;

  static Future<bool> joinCampfire({
    required String channelId,
    required String worldId,
    required String residentId,
    required String residentName,
  }) async {
    if (_currentRoom != null) await leaveCampfire();

    final token = await _fetchToken(channelId, worldId, residentId);
    if (token == null) return false;

    final room = Room();
    await room.connect(token['livekitUrl'] as String, token['token'] as String);

    room.addListener(_onRoomUpdate);
    room.addListener(_onConnectionChange);
    _currentRoom = room;

    if (_participantsController == null || _participantsController!.isClosed) {
      _participantsController = StreamController<List<Participant>>.broadcast();
      _disposed = false;
    }
    _onRoomUpdate();
    return true;
  }

  static Future<Map<String, dynamic>?> _fetchToken(
    String channelId,
    String worldId,
    String residentId,
  ) async {
    if (!isSupabaseConfigured()) return null;
    try {
      final client = getSupabase();
      final session = client.auth.currentSession;
      if (session == null) return null;

      final res = await client.functions.invoke(
        'livekit-token',
        body: {
          'channelId': channelId,
          'worldId': worldId,
          'participantIdentity': residentId,
        },
      );
      return res.data as Map<String, dynamic>?;
    } catch (e, st) {
      CrashReporter.instance.recordError(
        e,
        st,
        hint: 'voice_service token fetch',
      );
      return null;
    }
  }

  static void _onConnectionChange() {
    final room = _currentRoom;
    if (room == null) return;
    if (room.connectionState == ConnectionState.disconnected) {
      onDisconnected?.call();
    }
  }

  static void _onRoomUpdate() {
    final room = _currentRoom;
    if (room == null) return;
    _participants.clear();
    final local = room.localParticipant;
    if (local != null) {
      _participants.add(local);
    }
    _participants.addAll(room.remoteParticipants.values);
    _participantsController?.add(List.unmodifiable(_participants));
  }

  static Future<void> leaveCampfire() async {
    _currentRoom?.removeListener(_onConnectionChange);
    await _currentRoom?.disconnect();
    _currentRoom?.removeListener(_onRoomUpdate);
    _currentRoom = null;
    _participants.clear();
    _participantsController?.add([]);
  }

  static Future<void> toggleMute() async {
    final local = _currentRoom?.localParticipant;
    if (local == null) return;
    await local.setMicrophoneEnabled(!local.isMicrophoneEnabled());
  }

  static Future<void> toggleDeafen() async {
    if (_currentRoom == null) return;
    final local = _currentRoom!.localParticipant;
    if (local == null) return;
    _isDeafened = !_isDeafened;
    await local.setMicrophoneEnabled(!_isDeafened);
  }

  static bool get isDeafened => _isDeafened;

  static bool get isMuted =>
      _currentRoom?.localParticipant?.isMicrophoneEnabled() == false;

  static bool get isSpeaking {
    final level = _currentRoom?.localParticipant?.audioLevel;
    return level != null && level > 0.01;
  }

  static double get audioLevel =>
      _currentRoom?.localParticipant?.audioLevel ?? 0.0;

  static void dispose() {
    _disposed = true;
    onDisconnected = null;
    _currentRoom?.removeListener(_onConnectionChange);
    _currentRoom?.removeListener(_onRoomUpdate);
    _currentRoom = null;
    _participants.clear();
    _participantsController?.close();
  }
}
