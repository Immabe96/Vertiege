import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'analytics_service.dart';
import 'app_check_service.dart';
import 'crash_reporter.dart';
import 'performance_service.dart';
import 'remote_config_service.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _initialized = false;
  static Object? _lastError;

  static bool get isInitialized => _initialized;
  static Object? get lastError => _lastError;

  static Future<void> initialize() async {
    await initializeCore();
    await initializeDeferred();
  }

  /// Firebase Core + Crashlytics only — keep startup light.
  static Future<void> initializeCore() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      CrashReporter.install(await FirebaseCrashReporter.create());
      _initialized = true;
      _lastError = null;
    } catch (error, stackTrace) {
      _initialized = false;
      _lastError = error;
      debugPrint('Firebase core init failed: $error');
      CrashReporter.instance.recordError(
        error,
        stackTrace,
        hint: 'firebase bootstrap core init',
      );
    }
  }

  /// Non-blocking extras — safe to run after first frame.
  static Future<void> initializeDeferred() async {
    if (!_initialized) return;
    try {
      await AppCheckService.initialize().timeout(const Duration(seconds: 4));
      await Future.wait([
        AnalyticsService.initialize(),
        PerformanceService.initialize(),
        RemoteConfigService.initialize(),
      ]).timeout(const Duration(seconds: 6));
    } catch (error, stackTrace) {
      CrashReporter.instance.recordError(
        error,
        stackTrace,
        hint: 'firebase bootstrap deferred init',
      );
    }
  }
}
