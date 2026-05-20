import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'analytics_events.dart';
import 'analytics_service.dart';
import 'crash_reporter.dart';
import 'firebase_bootstrap.dart';
import 'firebase_messaging_handlers.dart';
import 'supabase.dart';

class PushTokenService {
  PushTokenService._();

  static final StreamController<String> _notificationRoutes =
      StreamController<String>.broadcast();
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static bool _messageHandlersRegistered = false;
  static String? _residentId;

  static Stream<String> get notificationRoutes => _notificationRoutes.stream;

  static Future<String?> initializeForResident(String residentId) async {
    if (!FirebaseBootstrap.isInitialized || kIsWeb || !isSupabaseConfigured()) {
      return null;
    }

    _residentId = residentId;
    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );

    final token = await messaging.getToken();
    await _upsertToken(token);
    _listenForTokenRefresh();
    _registerMessageHandlers();

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage == null) return null;
    await _recordMessageEvent('notification_initial_open', initialMessage);
    return routeFromRemoteMessage(initialMessage);
  }

  static Future<void> registerForResident(String residentId) async {
    await initializeForResident(residentId);
  }

  static void _listenForTokenRefresh() {
    _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
        .listen(
          (token) => unawaited(_upsertToken(token)),
          onError: (Object error, StackTrace stackTrace) {
            CrashReporter.instance.recordError(
              error,
              stackTrace,
              hint: 'fcm token refresh',
            );
          },
        );
  }

  static void _registerMessageHandlers() {
    if (_messageHandlersRegistered) return;
    _messageHandlersRegistered = true;

    FirebaseMessaging.onMessage.listen((message) {
      unawaited(_recordMessageEvent('notification_foreground', message));
      CrashReporter.instance.addBreadcrumb(
        message.messageId ?? 'foreground message',
        category: 'fcm',
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(_recordMessageEvent('notification_opened', message));
      final route = routeFromRemoteMessage(message);
      if (route != null) _notificationRoutes.add(route);
    });
  }

  static Future<void> _upsertToken(String? token) async {
    final residentId = _residentId;
    if (residentId == null || token == null || token.isEmpty) return;

    await getSupabase().from('device_tokens').upsert({
      'resident_id': residentId,
      'token': token,
      'platform': defaultTargetPlatform.name,
      'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'token');
  }

  static Future<void> _recordMessageEvent(
    String eventName,
    RemoteMessage message,
  ) async {
    await AnalyticsService.logEvent(
      eventName,
      parameters: {
        'message_id': message.messageId ?? 'unknown',
        if (message.data['type'] != null) 'type': '${message.data['type']}',
        if (message.data['world_id'] != null)
          'world_id': '${message.data['world_id']}',
      },
    );
    if (eventName == 'notification_opened') {
      await AnalyticsService.logEvent(AnalyticsEvents.notificationOpened);
    }
  }
}
