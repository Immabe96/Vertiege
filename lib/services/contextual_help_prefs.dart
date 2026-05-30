import 'package:shared_preferences/shared_preferences.dart';

import 'onboarding_funnel_prefs.dart';

/// When to show inline explanatory copy (not the optional ? help sheet).
class ContextualHelpPrefs {
  ContextualHelpPrefs._();

  /// True until the user dismisses "Your first steps" or has fully onboarded.
  static Future<bool> shouldShowContextualHelp() async {
    if (await OnboardingFunnelPrefs.consumeJustFinishedOnboarding()) {
      return true;
    }
    if (await OnboardingFunnelPrefs.isDismissed()) {
      return false;
    }
    return true;
  }

  /// Optional per-surface dismiss (e.g. user closed a hint on one screen).
  static Future<bool> isSurfaceHintDismissed(String surfaceId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('contextual_help_$surfaceId') ?? false;
  }

  static Future<void> dismissSurfaceHint(String surfaceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('contextual_help_$surfaceId', true);
  }
}
