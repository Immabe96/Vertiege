import 'package:shared_preferences/shared_preferences.dart';

/// Local preferences for world detail navigation (Release 3).
class WorldNavPrefs {
  WorldNavPrefs._();

  static const memberOpensOnFeedKey = 'world_member_opens_on_feed';
  static const askedFeedDefaultKey = 'world_member_feed_pref_asked';

  static Future<bool> memberOpensOnFeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(memberOpensOnFeedKey) ?? true;
  }

  static Future<void> setMemberOpensOnFeed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(memberOpensOnFeedKey, value);
    await prefs.setBool(askedFeedDefaultKey, true);
  }

  static Future<bool> hasAskedFeedDefault() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(askedFeedDefaultKey) ?? false;
  }
}
