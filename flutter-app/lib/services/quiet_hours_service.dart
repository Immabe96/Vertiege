import '../models/quiet_hours.dart';
import '../services/supabase.dart';

class QuietHoursService {
  static Future<QuietHours> getQuietHours(String worldId) async {
    if (!isSupabaseConfigured()) {
      return QuietHours(worldId: worldId);
    }
    final client = getSupabase();
    final data = await client
        .from('world_quiet_hours')
        .select()
        .eq('world_id', worldId)
        .maybeSingle();
    if (data == null) return QuietHours(worldId: worldId);
    return QuietHours.fromSupabase(data);
  }

  static Future<void> setQuietHours(
    String worldId, {
    required int startHour,
    required int endHour,
    required bool enabled,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('world_quiet_hours').upsert({
      'world_id': worldId,
      'start_hour': startHour,
      'end_hour': endHour,
      'enabled': enabled,
    });
  }

  static Future<bool> isQuietTime(String worldId) async {
    final quietHours = await getQuietHours(worldId);
    if (!quietHours.enabled) return false;

    final now = DateTime.now();
    final currentHour = now.hour;

    if (quietHours.startHour > quietHours.endHour) {
      return currentHour >= quietHours.startHour ||
          currentHour < quietHours.endHour;
    } else {
      return currentHour >= quietHours.startHour &&
          currentHour < quietHours.endHour;
    }
  }
}
