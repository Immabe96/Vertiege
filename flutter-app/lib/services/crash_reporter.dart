import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crash reporting abstraction.
///
/// [FirebaseCrashReporter] is installed from [FirebaseBootstrap.initializeCore]
/// on mobile when Firebase initializes. [ConsoleCrashReporter] is the fallback
/// when Firebase is unavailable (e.g. desktop `flutter run` on Linux).
///
/// Usage in catch blocks:
///   ```dart
///   } catch (e, stack) {
///     CrashReporter.instance.recordError(e, stack, hint: 'loading posts');
///   }
///   ```
abstract class CrashReporter {
  static CrashReporter? _instance;

  static CrashReporter get instance => _instance ??= ConsoleCrashReporter();

  static void install(CrashReporter reporter) {
    _instance = reporter;
  }

  /// Record a caught exception. Call this in every silent catch block.
  void recordError(Object error, StackTrace stack, {String? hint});

  /// Record a breadcrumb for navigation/auth events.
  void addBreadcrumb(String message, {String? category});

  /// Set user identifier for crash context.
  void setUser(String id, {String? name});

  /// Set a custom key-value pair for crash context.
  void setCustomKey(String key, String value);

  /// Log a non-fatal event (for analytics/debugging).
  void log(String message);
}

class ConsoleCrashReporter implements CrashReporter {
  @override
  void recordError(Object error, StackTrace stack, {String? hint}) {
    debugPrint('CRASH: ${hint ?? "error"}: $error\n$stack');
  }

  @override
  void addBreadcrumb(String message, {String? category}) {
    debugPrint('BREADCRUMB${category != null ? " [$category]" : ""}: $message');
  }

  @override
  void setUser(String id, {String? name}) {
    debugPrint('USER: $id${name != null ? " ($name)" : ""}');
  }

  @override
  void setCustomKey(String key, String value) {
    debugPrint('KEY: $key = $value');
  }

  @override
  void log(String message) {
    debugPrint('LOG: $message');
  }
}

class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  static Future<FirebaseCrashReporter> create() async {
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
    return FirebaseCrashReporter(crashlytics);
  }

  @override
  void recordError(Object error, StackTrace stack, {String? hint}) {
    _crashlytics.recordError(error, stack, reason: hint);
  }

  @override
  void addBreadcrumb(String message, {String? category}) {
    _crashlytics.log(category == null ? message : '[$category] $message');
  }

  @override
  void setUser(String id, {String? name}) {
    _crashlytics.setUserIdentifier(id);
    if (name != null && name.isNotEmpty) {
      _crashlytics.setCustomKey('resident_name_available', true);
    }
  }

  @override
  void setCustomKey(String key, String value) {
    _crashlytics.setCustomKey(key, value);
  }

  @override
  void log(String message) {
    _crashlytics.log(message);
  }
}

/// Convenience function for catch blocks — no import needed beyond this file.
void reportError(Object error, StackTrace stack, {String? hint}) {
  CrashReporter.instance.recordError(error, stack, hint: hint);
}
