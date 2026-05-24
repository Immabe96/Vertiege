import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'firebase_bootstrap.dart';

class RemoteConfigService {
  RemoteConfigService._();

  static FirebaseRemoteConfig? _remoteConfig;

  static Future<void> initialize() async {
    if (!FirebaseBootstrap.isInitialized) return;
    _remoteConfig = FirebaseRemoteConfig.instance;
    await _remoteConfig?.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await _remoteConfig?.setDefaults(const {
      // Feature flags
      'marketplace_enabled': false,
      'treasury_enabled': false,
      'quests_enabled': true,
      'events_enabled': true,
      'polls_enabled': false,
      'challenges_enabled': false,
      // UI
      'forui_strict_mode': true,
      'post_outbox_enabled': true,
      'verbose_errors': false,
      // Pagination
      'feed_page_size': 20,
      'comments_page_size': 20,
      'chat_page_size': 30,
      'notifications_page_size': 20,
      'marketplace_page_size': 20,
      'residents_page_size': 20,
      // Performance
      'startup_load_limit': 20,
      // App
      'minimum_build': 1,
      'maintenance_banner': '',
    });
    await _remoteConfig?.fetchAndActivate().timeout(
      const Duration(seconds: 5),
      onTimeout: () => false,
    );
  }

  static bool getBool(String key, {bool fallback = false}) {
    if (!FirebaseBootstrap.isInitialized || _remoteConfig == null) {
      return fallback;
    }
    return _remoteConfig!.getBool(key);
  }

  static int getInt(String key, {int fallback = 0}) {
    if (!FirebaseBootstrap.isInitialized || _remoteConfig == null) {
      return fallback;
    }
    return _remoteConfig!.getInt(key);
  }

  static String getString(String key, {String fallback = ''}) {
    if (!FirebaseBootstrap.isInitialized || _remoteConfig == null) {
      return fallback;
    }
    return _remoteConfig!.getString(key);
  }
}
