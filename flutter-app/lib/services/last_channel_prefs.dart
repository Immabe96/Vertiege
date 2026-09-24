import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Last-opened channel per world — local resume (DCX-021).
class LastChannelPrefs {
  LastChannelPrefs._();

  static const _key = '@last_channel_by_world';

  static Future<Map<String, String>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  static Future<String?> loadForWorld(String worldId) async {
    final all = await loadAll();
    return all[worldId];
  }

  static Future<void> save({
    required String worldId,
    required String channelId,
  }) async {
    final all = await loadAll();
    all[worldId] = channelId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(all));
  }
}
