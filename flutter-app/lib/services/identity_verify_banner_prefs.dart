import 'package:shared_preferences/shared_preferences.dart';

/// Session/local dismiss for the You-tab government-ID verification banner.
class IdentityVerifyBannerPrefs {
  IdentityVerifyBannerPrefs._();

  static const _dismissedKey = 'identity_verify_banner_dismissed';

  static Future<bool> isDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dismissedKey) ?? false;
  }

  static Future<void> dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }

  static Future<void> clearDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedKey);
  }
}
