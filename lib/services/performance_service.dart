import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';
import 'firebase_bootstrap.dart';

class PerformanceService {
  PerformanceService._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!FirebaseBootstrap.isInitialized || _initialized) return;
    try {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        !kDebugMode,
      );
      _initialized = true;
    } catch (error, stackTrace) {
      _initialized = false;
      CrashReporter.instance.recordError(
        error,
        stackTrace,
        hint: 'firebase performance init',
      );
    }
  }

  static Future<T> trace<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String> attributes = const {},
    Map<String, int> metrics = const {},
  }) async {
    if (!FirebaseBootstrap.isInitialized || !_initialized) {
      return action();
    }

    final trace = FirebasePerformance.instance.newTrace(name);
    for (final entry in attributes.entries) {
      trace.putAttribute(entry.key, entry.value);
    }
    for (final entry in metrics.entries) {
      trace.setMetric(entry.key, entry.value);
    }

    await trace.start();
    try {
      final result = await action();
      trace.putAttribute('status', 'success');
      return result;
    } catch (error) {
      trace.putAttribute('status', 'error');
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}
