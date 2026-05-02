import 'dart:async';
import 'dart:convert';
import 'dart:ui' show VoidCallback;
import 'package:shared_preferences/shared_preferences.dart';

final Map<String, Timer> _timers = {};

void debounceWrite(String key, void Function() fn, {int delay = 300}) {
  _timers[key]?.cancel();
  _timers[key] = Timer(Duration(milliseconds: delay), fn);
}

class StorageService {
  StorageService._();

  static const String residentKey = '@resident_data';
  static const String postsKey = '@posts_data';
  static const String notificationsKey = '@notifications_data';
  static const String achievementsKey = '@achievements_data';
  static const String themeKey = '@theme_preference';
  static const String channelsKey = '@channels_data';
  static const String membershipsKey = '@memberships_data';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  static Future<void> setStringDebounced(String key, String value) async {
    debounceWrite(key, () => setString(key, value));
  }

  static Future<void> remove(String key) async {
    final prefs = await _prefs;
    await prefs.remove(key);
  }

  static Future<Map<String, String>> getAll(List<String> keys) async {
    final prefs = await _prefs;
    final result = <String, String>{};
    for (final key in keys) {
      final value = prefs.getString(key);
      if (value != null) result[key] = value;
    }
    return result;
  }

  static Future<void> clearAll() async {
    final prefs = await _prefs;
    for (final key in [residentKey, postsKey, notificationsKey, achievementsKey, themeKey, channelsKey, membershipsKey]) {
      await prefs.remove(key);
    }
  }
}
