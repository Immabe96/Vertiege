import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'crash_reporter.dart';
import 'supabase.dart';

/// Live sync when staff verifies an achievement (complements notifications).
class AchievementRealtimeService {
  AchievementRealtimeService._();

  static RealtimeChannel? _channel;
  static String? _userId;
  static void Function()? _onVerified;
  static Timer? _debounce;

  static Future<void> initialize({
    required String userId,
    required void Function() onVerified,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    if (client.auth.currentUser?.id != userId) return;

    if (_initializedFor(userId)) return;
    await dispose();

    _userId = userId;
    _onVerified = onVerified;

    void handleRecord(Map<String, dynamic> record) {
      if (record['status']?.toString() != 'verified') return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        _onVerified?.call();
      });
    }

    _channel = client
        .channel('user_achievements_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_achievements',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              handleRecord(payload.newRecord);
            } catch (e, st) {
              CrashReporter.instance.recordError(
                e,
                st,
                hint: 'achievement_realtime insert',
              );
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_achievements',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final oldStatus = payload.oldRecord['status']?.toString();
              final newStatus = payload.newRecord['status']?.toString();
              if (newStatus == 'verified' && oldStatus != 'verified') {
                handleRecord(payload.newRecord);
              }
            } catch (e, st) {
              CrashReporter.instance.recordError(
                e,
                st,
                hint: 'achievement_realtime update',
              );
            }
          },
        )
        .subscribe();
  }

  static bool _initializedFor(String userId) =>
      _userId == userId && _channel != null;

  static Future<void> dispose() async {
    _debounce?.cancel();
    _debounce = null;
    await _channel?.unsubscribe();
    _channel = null;
    _userId = null;
    _onVerified = null;
  }
}
