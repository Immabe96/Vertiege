import 'dart:async';

import 'supabase.dart';

/// Heartbeat + occupancy for Campfire voice channels (Wave 19).
class VoicePresenceService {
  VoicePresenceService._();

  static Timer? _heartbeatTimer;
  static String? _activeChannelId;
  static String? _activeWorldId;

  static Future<int> heartbeat(String channelId, String worldId) async {
    if (!isSupabaseConfigured()) return 0;
    try {
      final raw = await getSupabase().rpc(
        'heartbeat_voice_presence',
        params: {'p_channel_id': channelId, 'p_world_id': worldId},
      );
      return (raw as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<int> occupancy(String channelId) async {
    if (!isSupabaseConfigured() || channelId.isEmpty) return 0;
    try {
      final raw = await getSupabase().rpc(
        'get_voice_channel_occupancy',
        params: {'p_channel_id': channelId},
      );
      return (raw as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static void startHeartbeat({
    required String channelId,
    required String worldId,
  }) {
    stopHeartbeat();
    _activeChannelId = channelId;
    _activeWorldId = worldId;
    unawaited(heartbeat(channelId, worldId));
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        final ch = _activeChannelId;
        final w = _activeWorldId;
        if (ch != null && w != null) {
          unawaited(heartbeat(ch, w));
        }
      },
    );
  }

  static void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _activeChannelId = null;
    _activeWorldId = null;
  }
}
