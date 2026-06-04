import 'package:shared_preferences/shared_preferences.dart';

import 'supabase.dart';

/// Syncs notification toggles between device prefs and `notification_preferences`.
abstract final class NotificationPreferencesService {
  static const likesKey = 'settings_likes_enabled';
  static const commentsKey = 'settings_comments_enabled';
  static const worldInvitesKey = 'settings_world_invites_enabled';
  static const tierUpgradesKey = 'settings_tier_upgrades_enabled';
  static const pushKey = 'settings_push_enabled';

  static Future<void> pullFromServer() async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    final raw = await client.rpc('get_notification_preferences');
    if (raw is! Map) return;
    final map = Map<String, dynamic>.from(raw);
    if (map['success'] != true) return;
    final prefs = map['preferences'];
    if (prefs is! Map) return;
    final remote = Map<String, dynamic>.from(prefs);
    final sp = await SharedPreferences.getInstance();
    await _setIfPresent(sp, likesKey, remote['likes_enabled']);
    await _setIfPresent(sp, commentsKey, remote['comments_enabled']);
    await _setIfPresent(sp, worldInvitesKey, remote['world_invites_enabled']);
    await _setIfPresent(sp, tierUpgradesKey, remote['tier_upgrades_enabled']);
    await _setIfPresent(sp, pushKey, remote['push_enabled']);
  }

  static Future<void> pushToServer({
    bool? likesEnabled,
    bool? commentsEnabled,
    bool? worldInvitesEnabled,
    bool? tierUpgradesEnabled,
    bool? pushEnabled,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.rpc(
      'upsert_notification_preferences',
      params: {
        if (likesEnabled != null) 'p_likes_enabled': likesEnabled,
        if (commentsEnabled != null) 'p_comments_enabled': commentsEnabled,
        if (worldInvitesEnabled != null)
          'p_world_invites_enabled': worldInvitesEnabled,
        if (tierUpgradesEnabled != null)
          'p_tier_upgrades_enabled': tierUpgradesEnabled,
        if (pushEnabled != null) 'p_push_enabled': pushEnabled,
      },
    );
  }

  static Future<void> _setIfPresent(
    SharedPreferences sp,
    String key,
    Object? value,
  ) async {
    if (value is! bool) return;
    await sp.setBool(key, value);
  }
}
