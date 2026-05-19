import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';
import 'crash_reporter.dart';
import 'remote_config_service.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;
  static Object? _lastError;

  static bool get isInitialized => _initialized;
  static Object? get lastError => _lastError;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _initialized = true;
      _lastError = null;
      await Future.wait([
        AnalyticsService.initialize(),
        RemoteConfigService.initialize(),
      ]);
    } catch (error, stackTrace) {
      _initialized = false;
      _lastError = error;
      debugPrint('Firebase disabled for this build: $error');
      CrashReporter.instance.recordError(
        error,
        stackTrace,
        hint: 'firebase bootstrap optional init',
      );
    }
  }
}
