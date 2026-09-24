import 'supabase.dart';

/// Updates [world_members.last_active_at] for the signed-in resident (Wave 18).
class WorldActivityService {
  WorldActivityService._();

  static Future<void> touchWorld(String worldId) async {
    if (!isSupabaseConfigured() || worldId.isEmpty) return;
    try {
      await getSupabase().rpc(
        'touch_world_member_activity',
        params: {'p_world_id': worldId},
      );
    } catch (_) {
      // Non-blocking presence signal.
    }
  }
}
