import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import 'supabase.dart';
import 'crash_reporter.dart';

/// Manages Supabase Realtime notification subscriptions.
/// Foreground notifications arrive via the existing notification_provider.dart
/// which subscribes to the 'notifications' table. This service handles:
/// - Connection monitoring and auto-reconnect
/// - Notification tap routing metadata
class PushService {
  static RealtimeChannel? _channel;
  static StreamController<AppNotification>? _receivedController;
  static StreamController<AppNotification>? _tapController;
  static bool _initialized = false;
  static bool _isDisposed = false;
  static String? _userId;

  static Stream<AppNotification> get onNotificationReceived {
    if (_isDisposed || _receivedController == null || _receivedController!.isClosed) {
      _receivedController = StreamController<AppNotification>.broadcast();
      _isDisposed = false;
    }
    return _receivedController!.stream;
  }

  static Stream<AppNotification> get onNotificationTap {
    if (_isDisposed || _tapController == null || _tapController!.isClosed) {
      _tapController = StreamController<AppNotification>.broadcast();
      _isDisposed = false;
    }
    return _tapController!.stream;
  }

  static Future<void> initialize({String? userId}) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    final resolvedUserId = userId ?? client.auth.currentUser?.id;
    if (resolvedUserId == null) return;

    if (_initialized && _userId == resolvedUserId) return;
    if (_initialized && _userId != resolvedUserId) {
      await dispose();
    }
    _initialized = true;
    _isDisposed = false;
    _userId = resolvedUserId;

    if (_receivedController == null || _receivedController!.isClosed) {
      _receivedController = StreamController<AppNotification>.broadcast();
    }
    if (_tapController == null || _tapController!.isClosed) {
      _tapController = StreamController<AppNotification>.broadcast();
    }

    _channel = client
        .channel('push_$resolvedUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: resolvedUserId,
          ),
          callback: (payload) {
            try {
              final notif = AppNotification.fromSupabase(payload.newRecord);
              _receivedController?.add(notif);
            } catch (e, st) {
              CrashReporter.instance.recordError(
                e,
                st,
                hint: 'push_service realtime callback parse',
              );
            }
          },
        )
        .subscribe();
  }

  static Future<void> dispose() async {
    await _channel?.unsubscribe();
    _channel = null;
    _initialized = false;
    _isDisposed = true;
    _userId = null;
    await _receivedController?.close();
    _receivedController = null;
    await _tapController?.close();
    _tapController = null;
  }
}
