import 'dart:async';
import 'package:livekit_client/livekit_client.dart';
import 'supabase.dart';

class VoiceService {
  static Room? _currentRoom;
  static final _participantsController = StreamController<List<Participant>>.broadcast();
  static final List<Participant> _participants = [];

  static Stream<List<Participant>> get participantsStream =>
      _participantsController.stream;

  static List<Participant> get participants => List.unmodifiable(_participants);

  static bool get isConnected => _currentRoom != null;

  static Future<void> joinCampfire({
    required String channelId,
    required String residentId,
    required String residentName,
  }) async {
    if (_currentRoom != null) await leaveCampfire();

    final token = await _fetchToken(channelId, residentId);
    if (token == null) return;

    final room = Room();
    await room.connect(
      token['livekitUrl'] as String,
      token['token'] as String,
    );

    room.addListener(_onRoomUpdate);
    _currentRoom = room;
  }

  static Future<Map<String, dynamic>?> _fetchToken(
    String channelId,
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
          'roomName': 'campfire_$channelId',
          'participantIdentity': residentId,
        },
      );
      return res.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
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
    _participantsController.add(List.unmodifiable(_participants));
  }

  static Future<void> leaveCampfire() async {
    await _currentRoom?.disconnect();
    _currentRoom?.removeListener(_onRoomUpdate);
    _currentRoom = null;
    _participants.clear();
    _participantsController.add([]);
  }

  static Future<void> toggleMute() async {
    await _currentRoom?.localParticipant?.setMicrophoneEnabled(
      _currentRoom!.localParticipant!.isMicrophoneEnabled(),
    );
  }

  static Future<void> toggleDeafen() async {
    if (_currentRoom == null) return;
    final local = _currentRoom!.localParticipant;
    if (local == null) return;
    final currentlyEnabled = local.isMicrophoneEnabled();
    await local.setMicrophoneEnabled(!currentlyEnabled);
  }

  static bool get isMuted =>
      _currentRoom?.localParticipant?.isMicrophoneEnabled() == false;

  static bool get isSpeaking => false;

  static void dispose() {
    _currentRoom?.removeListener(_onRoomUpdate);
    _currentRoom = null;
    _participants.clear();
    _participantsController.close();
  }
}
