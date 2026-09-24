import 'package:shared_preferences/shared_preferences.dart';

import '../config/build_info.dart';
import 'feature_flags.dart';

/// One-shot "What's new" dialog driven by Remote Config.
class WhatsNewService {
  WhatsNewService._();

  static const _seenBuildKey = 'whats_new_seen_build';

  static Future<bool> shouldShow() async {
    final target = FeatureFlags.whatsNewBuild;
    final message = FeatureFlags.whatsNewMessage.trim();
    if (target <= 0 || message.isEmpty) return false;
    if (target > kAppBuildNumber) return false;

    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getInt(_seenBuildKey) ?? 0;
    return seen < target;
  }

  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seenBuildKey, FeatureFlags.whatsNewBuild);
  }
}
