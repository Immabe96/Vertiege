import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Worlds with notifications / unread badges suppressed on the rail.
class WorldMutePrefs {
  WorldMutePrefs._();

  static const _key = '@muted_world_notification_ids';

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return {};
    return raw.toSet();
  }

  static Future<Set<String>> toggle(String worldId) async {
    final current = await load();
    if (current.contains(worldId)) {
      current.remove(worldId);
    } else {
      current.add(worldId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, current.toList());
    return current;
  }

  static Future<bool> isMuted(String worldId) async {
    final all = await load();
    return all.contains(worldId);
  }
}
