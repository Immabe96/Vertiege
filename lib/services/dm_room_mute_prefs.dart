import 'package:shared_preferences/shared_preferences.dart';

/// DM rooms with notifications / unread badges suppressed.
class DmRoomMutePrefs {
  DmRoomMutePrefs._();

  static const _key = '@muted_dm_room_ids';

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key);
    if (raw == null) return {};
    return raw.toSet();
  }

  static Future<Set<String>> toggle(String roomId) async {
    final current = await load();
    if (current.contains(roomId)) {
      current.remove(roomId);
    } else {
      current.add(roomId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, current.toList());
    return current;
  }

  static Future<bool> isMuted(String roomId) async {
    final all = await load();
    return all.contains(roomId);
  }
}
