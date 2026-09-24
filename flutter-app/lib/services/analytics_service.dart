import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

import 'firebase_bootstrap.dart';

class AnalyticsService {
  AnalyticsService._();

  static FirebaseAnalytics? _analytics;

  static Future<void> initialize() async {
    if (!FirebaseBootstrap.isInitialized) return;
    _analytics = FirebaseAnalytics.instance;
    await _analytics?.setAnalyticsCollectionEnabled(true);
  }

  static List<NavigatorObserver> get navigatorObservers {
    final analytics = _analytics;
    if (!FirebaseBootstrap.isInitialized || analytics == null) return const [];
    return [FirebaseAnalyticsObserver(analytics: analytics)];
  }

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!FirebaseBootstrap.isInitialized) return;
    await _analytics?.logEvent(name: name, parameters: parameters);
  }

  static Future<void> setUser(String id) async {
    if (!FirebaseBootstrap.isInitialized) return;
    await _analytics?.setUserId(id: id);
  }
}
