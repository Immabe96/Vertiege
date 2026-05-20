import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';
import 'firebase_bootstrap.dart';

class AppCheckService {
  AppCheckService._();

  static bool _activated = false;

  static bool get isActivated => _activated;

  static Future<void> initialize() async {
    if (!FirebaseBootstrap.isInitialized || kIsWeb || _activated) return;

    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttestWithDeviceCheckFallback,
      );
      _activated = true;
    } catch (error, stackTrace) {
      _activated = false;
      CrashReporter.instance.recordError(
        error,
        stackTrace,
        hint: 'firebase app check init',
      );
    }
  }
}
