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
      'forui_strict_mode': true,
      'post_outbox_enabled': true,
    });
    await _remoteConfig?.fetchAndActivate();
  }

  static bool getBool(String key, {bool fallback = false}) {
    if (!FirebaseBootstrap.isInitialized || _remoteConfig == null) {
      return fallback;
    }
    return _remoteConfig!.getBool(key);
  }
}
