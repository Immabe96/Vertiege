import 'package:flutter/foundation.dart';

/// Crash reporting abstraction.
///
/// Currently logs to console. To enable Crashlytics:
///   1. Add firebase_core + firebase_crashlytics to pubspec.yaml
///   2. Add google-services.json / GoogleService-Info.plist
///   3. Replace [ConsoleCrashReporter] with [FirebaseCrashReporter] in main()
///
/// Usage in catch blocks:
///   ```dart
///   } catch (e, stack) {
///     CrashReporter.instance.recordError(e, stack, hint: 'loading posts');
///   }
///   ```
abstract class CrashReporter {
  static CrashReporter instance = ConsoleCrashReporter();

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

/// Convenience function for catch blocks — no import needed beyond this file.
void reportError(Object error, StackTrace stack, {String? hint}) {
  CrashReporter.instance.recordError(error, stack, hint: hint);
}
