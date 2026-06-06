import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/identity_verification.dart';
import 'crash_reporter.dart';
import 'supabase.dart';

/// Live profile gamification + identity verification for the signed-in resident.
class ResidentRealtimeService {
  ResidentRealtimeService._();

  static RealtimeChannel? _channel;
  static String? _userId;
  static void Function()? _onGamificationChange;
  static void Function()? _onIdentityVerified;
  static Timer? _gamificationDebounce;
  static Timer? _identityDebounce;

  static Future<void> initialize({
    required String userId,
    required void Function() onGamificationChange,
    required void Function() onIdentityVerified,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    if (client.auth.currentUser?.id != userId) return;

    if (_initializedFor(userId)) return;
    await dispose();

    _userId = userId;
    _onGamificationChange = onGamificationChange;
    _onIdentityVerified = onIdentityVerified;

    _channel = client
        .channel('resident_sync_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final oldXp = payload.oldRecord['total_xp'];
              final newXp = payload.newRecord['total_xp'];
              final oldTier = payload.oldRecord['tier'];
              final newTier = payload.newRecord['tier'];
              if (oldXp == newXp && oldTier == newTier) return;
              _gamificationDebounce?.cancel();
              _gamificationDebounce = Timer(
                const Duration(milliseconds: 400),
                () => _onGamificationChange?.call(),
              );
            } catch (e, st) {
              CrashReporter.instance.recordError(
                e,
                st,
                hint: 'resident_realtime profiles',
              );
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'verification_submissions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'resident_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final profession =
                  payload.newRecord['profession']?.toString() ?? '';
              final newStatus = payload.newRecord['status']?.toString();
              final oldStatus = payload.oldRecord['status']?.toString();
              if (newStatus != 'verified' || oldStatus == 'verified') return;
              if (!IdentityVerification.isIdentityProfession(profession)) {
                return;
              }
              _identityDebounce?.cancel();
              _identityDebounce = Timer(
                const Duration(milliseconds: 400),
                () => _onIdentityVerified?.call(),
              );
            } catch (e, st) {
              CrashReporter.instance.recordError(
                e,
                st,
                hint: 'resident_realtime verification',
              );
            }
          },
        )
        .subscribe();
  }

  static bool _initializedFor(String userId) =>
      _userId == userId && _channel != null;

  static Future<void> dispose() async {
    _gamificationDebounce?.cancel();
    _identityDebounce?.cancel();
    _gamificationDebounce = null;
    _identityDebounce = null;
    await _channel?.unsubscribe();
    _channel = null;
    _userId = null;
    _onGamificationChange = null;
    _onIdentityVerified = null;
  }
}
