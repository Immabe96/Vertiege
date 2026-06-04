import 'package:shared_preferences/shared_preferences.dart';

/// Tracks first-session funnel progress (profile → world → nexus → proof).
class OnboardingFunnelPrefs {
  OnboardingFunnelPrefs._();

  static const dismissedKey = 'onboarding_funnel_dismissed';
  static const openedWorldKey = 'onboarding_funnel_opened_world';
  static const openedNexusKey = 'onboarding_funnel_opened_nexus';
  static const justFinishedKey = 'onboarding_just_finished';

  static Future<bool> isDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(dismissedKey) ?? false;
  }

  static Future<void> setDismissed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dismissedKey, value);
  }

  static Future<bool> hasOpenedWorld() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(openedWorldKey) ?? false;
  }

  static Future<void> markOpenedWorld() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(openedWorldKey, true);
  }

  static Future<bool> hasOpenedNexus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(openedNexusKey) ?? false;
  }

  static Future<void> markOpenedNexus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(openedNexusKey, true);
  }

  static Future<void> markJustFinishedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(justFinishedKey, true);
  }

  /// Returns true once, then clears the flag.
  static Future<bool> consumeJustFinishedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(justFinishedKey) ?? false)) return false;
    await prefs.setBool(justFinishedKey, false);
    return true;
  }

  static Future<Map<String, dynamic>> readSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'dismissed': prefs.getBool(dismissedKey) ?? false,
      'opened_world': prefs.getBool(openedWorldKey) ?? false,
      'opened_nexus': prefs.getBool(openedNexusKey) ?? false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Remote wins for progress flags (never clears local true → false).
  static Future<void> applyRemote(Map<String, dynamic> remote) async {
    final prefs = await SharedPreferences.getInstance();
    if (remote['dismissed'] == true) {
      await prefs.setBool(dismissedKey, true);
    }
    if (remote['opened_world'] == true) {
      await prefs.setBool(openedWorldKey, true);
    }
    if (remote['opened_nexus'] == true) {
      await prefs.setBool(openedNexusKey, true);
    }
  }

}
