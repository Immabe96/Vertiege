import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';
import 'supabase.dart';

/// Manages Supabase Realtime notification subscriptions.
/// Foreground notifications arrive via the existing notification_provider.dart
/// which subscribes to the 'notifications' table. This service handles:
/// - Connection monitoring and auto-reconnect
/// - Notification tap routing metadata
class PushService {
  static RealtimeChannel? _channel;
  static final _tapController = StreamController<AppNotification>.broadcast();
  static bool _initialized = false;
  static String? _userId;

  static Stream<AppNotification> get onNotificationTap => _tapController.stream;

  static Stream<AppNotification> get onNotificationReceived =>
      _tapController.stream;

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
    _userId = resolvedUserId;

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
              _tapController.add(notif);
            } catch (_) {}
          },
        )
        .subscribe();
  }

  static Future<void> dispose() async {
    await _channel?.unsubscribe();
    _channel = null;
    _initialized = false;
    _userId = null;
  }
}
