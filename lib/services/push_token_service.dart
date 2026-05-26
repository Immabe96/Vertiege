import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'analytics_events.dart';
import 'device_permission_service.dart';
import 'analytics_service.dart';
import 'crash_reporter.dart';
import 'firebase_bootstrap.dart';
import 'firebase_messaging_handlers.dart';
import 'local_notification_service.dart';
import 'storage_service.dart';
import 'supabase.dart';

class PushTokenService {
  PushTokenService._();

  static final StreamController<String> _notificationRoutes =
      StreamController<String>.broadcast();
  static final StreamController<RemoteMessage> _foregroundMessages =
      StreamController<RemoteMessage>.broadcast();
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static bool _messageHandlersRegistered = false;
  static String? _residentId;

  static Stream<String> get notificationRoutes => _notificationRoutes.stream;
  static Stream<RemoteMessage> get foregroundMessages =>
      _foregroundMessages.stream;

  static Future<String?> initializeForResident(String residentId) async {
    if (!FirebaseBootstrap.isInitialized) {
      await _debugLog('push_init_skipped', 'Firebase not initialized');
      return null;
    }
    if (kIsWeb) {
      await _debugLog('push_init_skipped', 'Running on web');
      return null;
    }
    if (!isSupabaseConfigured()) {
      await _debugLog('push_init_skipped', 'Supabase not configured');
      return null;
    }

    _residentId = residentId;
    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    await _ensurePermission(messaging);

    try {
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        await _debugLog('push_no_token', 'FCM getToken returned null/empty');
      } else {
        await _upsertToken(token);
        await _debugLog(
          'push_token_registered',
          'Token upserted: ${token.length} chars',
        );
      }
    } catch (e, st) {
      await _debugLog('push_token_error', '$e');
      CrashReporter.instance.recordError(e, st, hint: 'fcm token registration');
    }
    _listenForTokenRefresh();
    _registerMessageHandlers();

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage == null) return null;
    await _recordMessageEvent('notification_initial_open', initialMessage);
    return routeFromRemoteMessage(initialMessage);
  }

  static Future<void> _debugLog(String tag, String message) async {
    if (!kDebugMode || !isSupabaseConfigured()) return;
    try {
      await getSupabase().from('debug_logs').insert({
        'tag': tag,
        'message': message,
      });
    } catch (_) {}
  }

  static Future<NotificationSettings> _ensurePermission(
    FirebaseMessaging messaging,
  ) async {
    await DevicePermissionService.requestNotifications();
    final settings = await messaging.getNotificationSettings();
    final status = settings.authorizationStatus.name;
    await StorageService.setString('push_permission_status', status);
    await _debugLog('push_permission_status', status);
    return settings;
  }

  static Future<void> registerForResident(String residentId) async {
    await initializeForResident(residentId);
  }

  static void _listenForTokenRefresh() {
    _tokenRefreshSubscription ??= FirebaseMessaging.instance.onTokenRefresh
        .listen(
          (token) {
            unawaited(_upsertToken(token));
            unawaited(
              _debugLog(
                'push_token_refreshed',
                'Token refreshed: ${token.length} chars',
              ),
            );
          },
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
      _foregroundMessages.add(message);
      unawaited(LocalNotificationService.showFromRemoteMessage(message));
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
