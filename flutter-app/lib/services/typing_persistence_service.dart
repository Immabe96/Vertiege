import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase.dart';

/// Server-backed DM typing (short TTL). Complements [TypingService] broadcast.
class TypingPersistenceService {
  TypingPersistenceService._();

  static const Duration activeWindow = Duration(seconds: 8);
  static const Duration persistThrottle = Duration(seconds: 2);

  static final Map<String, DateTime> _lastPersistAt = {};

  static Future<void> setTyping({
    required String roomId,
    required bool isTyping,
  }) async {
    if (!isSupabaseConfigured()) return;

    final key = roomId;
    if (isTyping) {
      final last = _lastPersistAt[key];
      final now = DateTime.now();
      if (last != null && now.difference(last) < persistThrottle) {
        return;
      }
      _lastPersistAt[key] = now;
    } else {
      _lastPersistAt.remove(key);
    }

    try {
      await getSupabase().rpc(
        'upsert_dm_typing',
        params: {
          'p_room_id': roomId,
          'p_is_typing': isTyping,
        },
      );
    } catch (_) {
      // Best-effort; broadcast remains primary for live UI.
    }
  }

  /// Active typers in [roomId] within [activeWindow], excluding [excludeUserId].
  static Future<List<String>> fetchActiveTypers(
    String roomId, {
    String? excludeUserId,
  }) async {
    if (!isSupabaseConfigured()) return [];

    final cutoff = DateTime.now().subtract(activeWindow).toUtc().toIso8601String();
    try {
      final rows = await getSupabase()
          .from('dm_typing')
          .select('user_id, updated_at')
          .eq('room_id', roomId)
          .gt('updated_at', cutoff);

      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map((r) => r['user_id'] as String?)
          .whereType<String>()
          .where((id) => excludeUserId == null || id != excludeUserId)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static RealtimeChannel? subscribeToRoom(
    String roomId,
    void Function(String userId, bool isTyping) onChange,
  ) {
    if (!isSupabaseConfigured()) return null;

    void handleUpsert(Map<String, dynamic> record) {
      final userId = record['user_id'] as String?;
      if (userId == null || userId.isEmpty) return;

      final updatedRaw = record['updated_at'] as String?;
      final updated =
          updatedRaw != null ? DateTime.tryParse(updatedRaw)?.toUtc() : null;
      final fresh = updated != null &&
          DateTime.now().toUtc().difference(updated) <= activeWindow;
      onChange(userId, fresh);
    }

    final filter = PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'room_id',
      value: roomId,
    );

    final channel = getSupabase()
        .channel('dm_typing_$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'dm_typing',
          filter: filter,
          callback: (payload) => handleUpsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'dm_typing',
          filter: filter,
          callback: (payload) => handleUpsert(payload.newRecord),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'dm_typing',
          filter: filter,
          callback: (payload) {
            final userId = payload.oldRecord['user_id'] as String?;
            if (userId != null && userId.isNotEmpty) {
              onChange(userId, false);
            }
          },
        )
        .subscribe();

    return channel;
  }
}
