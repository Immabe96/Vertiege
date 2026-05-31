import 'package:shared_preferences/shared_preferences.dart';

/// One-time prompt to enable push after account setup.
class NotificationOnboardingPrefs {
  NotificationOnboardingPrefs._();

  static const _kCompleted = 'notification_onboarding_completed';

  static Future<bool> shouldPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kCompleted) ?? false);
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCompleted, true);
  }
}
