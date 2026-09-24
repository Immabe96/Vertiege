import '../models/channel_mute_mode.dart';
import 'supabase.dart';

class ChannelMuteService {
  static Future<Map<String, ChannelMuteMode>> getMutePrefs(
    String residentId,
  ) async {
    if (!isSupabaseConfigured()) return {};
    final client = getSupabase();
    final data = await client
        .from('channel_mute_prefs')
        .select('channel_id, mute_mode')
        .eq('resident_id', residentId);
    final map = <String, ChannelMuteMode>{};
    for (final row in (data as List).cast<Map<String, dynamic>>()) {
      final channelId = row['channel_id'] as String?;
      if (channelId == null || channelId.isEmpty) continue;
      map[channelId] = ChannelMuteMode.fromStorage(row['mute_mode'] as String?);
    }
    return map;
  }

  static Future<ChannelMuteMode> getMuteMode({
    required String residentId,
    required String channelId,
  }) async {
    if (!isSupabaseConfigured()) return ChannelMuteMode.off;
    final client = getSupabase();
    final data = await client
        .from('channel_mute_prefs')
        .select('mute_mode')
        .eq('resident_id', residentId)
        .eq('channel_id', channelId)
        .maybeSingle();
    return ChannelMuteMode.fromStorage(data?['mute_mode'] as String?);
  }

  static Future<void> setMuteMode({
    required String residentId,
    required String channelId,
    required ChannelMuteMode mode,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    if (mode == ChannelMuteMode.off) {
      await client
          .from('channel_mute_prefs')
          .delete()
          .eq('resident_id', residentId)
          .eq('channel_id', channelId);
      return;
    }
    await client.from('channel_mute_prefs').upsert({
      'resident_id': residentId,
      'channel_id': channelId,
      'mute_mode': mode.storageValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
