import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import '../utils/haptics.dart';
import 'analytics_events.dart';
import 'analytics_service.dart';
import 'crash_reporter.dart';
import 'supabase.dart';
import 'voice_presence_service.dart';

class VoiceService {
  static Room? _currentRoom;
  static StreamController<List<Participant>>? _participantsController;
  static final List<Participant> _participants = [];
  static bool _disposed = false;
  static bool _isDeafened = false;
  static bool _intentionalLeave = false;
  static int _reconnectAttempt = 0;
  static Timer? _reconnectTimer;

  static String? _channelId;
  static String? _worldId;
  static String? _residentId;

  static VoidCallback? onDisconnected;
  static VoidCallback? onReconnecting;
  static VoidCallback? onReconnected;

  static const _maxReconnectAttempts = 6;

  static Stream<List<Participant>> get participantsStream {
    if (_disposed ||
        _participantsController == null ||
        _participantsController!.isClosed) {
      _participantsController = StreamController<List<Participant>>.broadcast();
      _disposed = false;
    }
    return _participantsController!.stream;
  }

  static List<Participant> get participants => List.unmodifiable(_participants);

  static bool get isConnected =>
      _currentRoom?.connectionState == ConnectionState.connected;

  static bool get isReconnecting =>
      _currentRoom?.connectionState == ConnectionState.reconnecting ||
      _reconnectTimer != null;

  static Future<bool> joinCampfire({
    required String channelId,
    required String worldId,
    required String residentId,
    required String residentName,
  }) async {
    _intentionalLeave = false;
    _reconnectAttempt = 0;
    _cancelReconnectTimer();
    _channelId = channelId;
    _worldId = worldId;
    _residentId = residentId;

    if (_currentRoom != null) await leaveCampfire();

    CrashReporter.instance.setCustomKey('voice_world_id', worldId);
    CrashReporter.instance.setCustomKey('voice_channel_id', channelId);

    final token = await _fetchToken(channelId, worldId, residentId);
    if (token == null) return false;

    final room = Room();
    try {
      await room.connect(
        token['livekitUrl'] as String,
        token['token'] as String,
      );
      await _configureBackgroundAudio();
    } catch (e, st) {
      CrashReporter.instance.recordError(
        e,
        st,
        hint: 'voice_service room connect',
      );
      return false;
    }

    room.addListener(_onRoomUpdate);
    room.addListener(_onConnectionChange);
    _currentRoom = room;

    if (_participantsController == null || _participantsController!.isClosed) {
      _participantsController = StreamController<List<Participant>>.broadcast();
      _disposed = false;
    }
    _onRoomUpdate();
    VoicePresenceService.startHeartbeat(
      channelId: channelId,
      worldId: worldId,
    );
    Haptics.medium();
    unawaited(
      AnalyticsService.logEvent(
        AnalyticsEvents.voiceJoined,
        parameters: {'world_id': worldId, 'channel_id': channelId},
      ),
    );
    CrashReporter.instance.addBreadcrumb(
      'campfire_connected',
      category: 'voice',
    );
    return true;
  }

  static Future<void> _configureBackgroundAudio() async {
    if (kIsWeb) return;
    try {
      await Hardware.instance.setSpeakerphoneOn(true);
    } catch (_) {
      // Best-effort; platform may restrict without background audio entitlement.
    }
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
      CrashReporter.instance.setCustomKey('voice_world_id', worldId);
      CrashReporter.instance.setCustomKey('voice_channel_id', channelId);
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

    switch (room.connectionState) {
      case ConnectionState.reconnecting:
        onReconnecting?.call();
        break;
      case ConnectionState.connected:
        if (_reconnectAttempt > 0) {
          _reconnectAttempt = 0;
          onReconnected?.call();
        }
        break;
      case ConnectionState.disconnected:
        if (_intentionalLeave) {
          onDisconnected?.call();
        } else {
          _scheduleReconnect();
        }
        break;
      default:
        break;
    }
  }

  static void _scheduleReconnect() {
    if (_intentionalLeave || _channelId == null || _residentId == null) return;
    if (_reconnectAttempt >= _maxReconnectAttempts) {
      onDisconnected?.call();
      return;
    }

    onReconnecting?.call();
    _cancelReconnectTimer();

    final delaySec = math.min(
      30,
      math.pow(2, _reconnectAttempt).toInt(),
    );
    _reconnectAttempt++;

    _reconnectTimer = Timer(Duration(seconds: delaySec), () async {
      final ok = await _reconnect();
      if (!ok && !_intentionalLeave) {
        _scheduleReconnect();
      }
    });
  }

  static Future<bool> _reconnect() async {
    final channelId = _channelId;
    final worldId = _worldId;
    final residentId = _residentId;
    if (channelId == null || residentId == null) return false;

    final token = await _fetchToken(channelId, worldId ?? '', residentId);
    if (token == null) return false;

    try {
      final room = _currentRoom;
      if (room != null) {
        await room.connect(
          token['livekitUrl'] as String,
          token['token'] as String,
        );
        _onRoomUpdate();
        _reconnectAttempt = 0;
        onReconnected?.call();
        return true;
      }
      return await joinCampfire(
        channelId: channelId,
        worldId: worldId ?? '',
        residentId: residentId,
        residentName: '',
      );
    } catch (e, st) {
      CrashReporter.instance.recordError(e, st, hint: 'voice_service reconnect');
      return false;
    }
  }

  static void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
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
    _intentionalLeave = true;
    _cancelReconnectTimer();
    VoicePresenceService.stopHeartbeat();
    _channelId = null;
    _worldId = null;
    _residentId = null;
    _reconnectAttempt = 0;
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
    onReconnecting = null;
    onReconnected = null;
    _intentionalLeave = true;
    _cancelReconnectTimer();
    VoicePresenceService.stopHeartbeat();
    _currentRoom?.removeListener(_onConnectionChange);
    _currentRoom?.removeListener(_onRoomUpdate);
    _currentRoom?.disconnect();
    _currentRoom = null;
    _participants.clear();
    _participantsController?.close();
  }
}
