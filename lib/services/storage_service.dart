import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  StorageService._();

  static final Map<String, Timer> _timers = {};
  static final Map<String, String> _pendingWrites = {};

  static const String residentKey = '@resident_data';
  static const String postsKey = '@posts_data';
  static const String notificationsKey = '@notifications_data';
  static const String chatMessagesKey = '@chat_messages_data';
  static const String achievementsKey = '@achievements_data';
  static const String themeKey = '@theme_preference';
  static const String channelsKey = '@channels_data';
  static const String membershipsKey = '@memberships_data';
  static const String userWorldsKey = '@user_worlds_data';

  /// Disk keys cleared on sign-out so the next session cannot leak prior user data.
  static const List<String> userSessionStorageKeys = [
    residentKey,
    postsKey,
    notificationsKey,
    chatMessagesKey,
    achievementsKey,
    channelsKey,
    membershipsKey,
    userWorldsKey,
    '@worlds_cache',
    '@events_data',
    '@quests_data',
    '@alliances_data',
    '@scheduled_posts',
    '@bookmarked_posts',
    '@cache_feed',
    '@cache_worlds',
  ];

  static Future<void> clearUserSessionData() async {
    flush();
    for (final key in userSessionStorageKeys) {
      await remove(key);
    }
  }

  static Future<SharedPreferences> get _prefs =>
      SharedPreferences.getInstance();

  static void debounceWrite(String key, void Function() fn, {int delay = 300}) {
    _timers[key]?.cancel();
    _timers[key] = Timer(Duration(milliseconds: delay), fn);
  }

  static void _flushPending() {
    for (final entry in _timers.entries) {
      entry.value.cancel();
      final value = _pendingWrites[entry.key];
      if (value != null) {
        setString(entry.key, value);
      }
    }
    _timers.clear();
    _pendingWrites.clear();
  }

  static Future<String?> getString(String key) async {
    final prefs = await _prefs;
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await _prefs;
    await prefs.setString(key, value);
  }

  /// Writes a string to SharedPreferences with a debounce delay.
  /// This prevents excessive disk writes when saving rapidly changing state.
  static Future<void> setStringDebounced(String key, String value) async {
    _pendingWrites[key] = value;
    debounceWrite(key, () {
      _pendingWrites.remove(key);
      setString(key, value);
    });
  }

  static void flush() {
    _flushPending();
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

  /// Records a referral code usage. Returns true if this is the first use
  /// of the given code, false if it was already tracked.
  static Future<bool> trackReferral(
    String referralCode,
    String newResidentId,
  ) async {
    final prefs = await _prefs;
    final key = 'referral_$referralCode';
    final existing = prefs.getString(key);
    if (existing != null && existing.isNotEmpty) {
      // Code already used — append but don't double-count
      return false;
    }
    await prefs.setString(key, newResidentId);
    return true;
  }

  /// Returns the resident ID who used a referral code, if any.
  static Future<String?> getReferralUser(String referralCode) async {
    final prefs = await _prefs;
    return prefs.getString('referral_$referralCode');
  }

  static Future<void> clearAll() async {
    final prefs = await _prefs;
    for (final key in [
      residentKey,
      postsKey,
      notificationsKey,
      chatMessagesKey,
      achievementsKey,
      themeKey,
      channelsKey,
      membershipsKey,
      userWorldsKey,
    ]) {
      await prefs.remove(key);
    }
  }
}
