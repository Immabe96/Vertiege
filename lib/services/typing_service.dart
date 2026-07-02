import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'typing_persistence_service.dart';
import 'supabase.dart';

class TypingService {
  static final Map<String, Map<String, DateTime>> _typingTimestamps = {};
  static final Map<String, Timer> _cleanupTimers = {};
  static final Map<String, Timer> _autoStopTimers = {};

  static const Duration _typingDuration = Duration(seconds: 5);
  static const Duration _cleanupDelay = Duration(seconds: 7);
  static const String _broadcastEvent = 'typing';

  static const int _maxListeners = 64;
  static final List<void Function(String roomId, String userId, bool isTyping)>
      _listeners = [];

  static final Map<String, int> _subscribeRefCounts = {};
  static final Map<String, RealtimeChannel> _channels = {};
  static final Map<String, RealtimeChannel> _postgresChannels = {};

  static Future<void> startTyping(String roomId, String userId) async {
    _applyLocalTyping(roomId, userId, isTyping: true);
    _scheduleAutoStop(roomId, userId);
    unawaited(
      TypingPersistenceService.setTyping(roomId: roomId, isTyping: true),
    );
    await _broadcastTyping(roomId, userId, isTyping: true);
  }

  static Future<void> stopTyping(String roomId, String userId) async {
    _cancelAutoStop(roomId, userId);
    _applyLocalTyping(roomId, userId, isTyping: false);
    unawaited(
      TypingPersistenceService.setTyping(roomId: roomId, isTyping: false),
    );
    await _broadcastTyping(roomId, userId, isTyping: false);
  }

  static List<String> getTypingUsers(String roomId, {String? excludeUserId}) {
    final timestamps = _typingTimestamps[roomId] ?? {};
    final now = DateTime.now();
    return timestamps.entries
        .where((e) => e.value.isAfter(now) && e.key != excludeUserId)
        .map((e) => e.key)
        .toList();
  }

  static void addListener(
    void Function(String roomId, String userId, bool isTyping) listener,
  ) {
    if (_listeners.length >= _maxListeners) {
      _listeners.removeAt(0);
    }
    _listeners.add(listener);
  }

  static void removeListener(
    void Function(String roomId, String userId, bool isTyping) listener,
  ) {
    _listeners.remove(listener);
  }

  /// Subscribes to realtime typing broadcasts for [roomId].
  /// Ref-counted so multiple UI listeners share one channel.
  static void subscribe(String roomId) {
    if (!isSupabaseConfigured()) return;

    final next = (_subscribeRefCounts[roomId] ?? 0) + 1;
    _subscribeRefCounts[roomId] = next;
    if (next > 1) return;

    final channel = getSupabase()
        .channel('typing_$roomId')
        .onBroadcast(
          event: _broadcastEvent,
          callback: (payload) {
            final data = _parseBroadcastPayload(payload);
            if (data == null) return;
            final remoteUserId = data['user_id'] as String?;
            final isTyping = _parseIsTyping(data['is_typing']);
            if (remoteUserId == null || remoteUserId.isEmpty) return;
            updateTypingFromRemote(roomId, remoteUserId, isTyping);
          },
        )
        .subscribe();

    _channels[roomId] = channel;

    final pg = TypingPersistenceService.subscribeToRoom(
      roomId,
      (remoteUserId, isTyping) =>
          updateTypingFromRemote(roomId, remoteUserId, isTyping),
    );
    if (pg != null) {
      _postgresChannels[roomId] = pg;
    }

    unawaited(_hydrateTypingFromServer(roomId));
  }

  static Future<void> _hydrateTypingFromServer(String roomId) async {
    final userIds = await TypingPersistenceService.fetchActiveTypers(roomId);
    for (final userId in userIds) {
      updateTypingFromRemote(roomId, userId, true);
    }
  }

  /// Decrements the subscription ref count and tears down the channel at zero.
  static void unsubscribe(String roomId) {
    if (!isSupabaseConfigured()) return;

    final count = _subscribeRefCounts[roomId];
    if (count == null) return;

    if (count <= 1) {
      _subscribeRefCounts.remove(roomId);
      final channel = _channels.remove(roomId);
      if (channel != null) {
        unawaited(channel.unsubscribe());
      }
      final pg = _postgresChannels.remove(roomId);
      if (pg != null) {
        unawaited(pg.unsubscribe());
      }
    } else {
      _subscribeRefCounts[roomId] = count - 1;
    }
  }

  static void updateTypingFromRemote(
    String roomId,
    String userId,
    bool isTyping,
  ) {
    if (isTyping) {
      _applyLocalTyping(roomId, userId, isTyping: true);
      _scheduleRemoteCleanup(roomId, userId);
    } else {
      _cleanupTimers['${roomId}_$userId']?.cancel();
      _cleanupTimers.remove('${roomId}_$userId');
      _applyLocalTyping(roomId, userId, isTyping: false);
    }
  }

  static void dispose() {
    for (final timer in _cleanupTimers.values) {
      timer.cancel();
    }
    for (final timer in _autoStopTimers.values) {
      timer.cancel();
    }
    _cleanupTimers.clear();
    _autoStopTimers.clear();
    _typingTimestamps.clear();
    _listeners.clear();

    for (final channel in _channels.values) {
      unawaited(channel.unsubscribe());
    }
    for (final channel in _postgresChannels.values) {
      unawaited(channel.unsubscribe());
    }
    _channels.clear();
    _postgresChannels.clear();
    _subscribeRefCounts.clear();
  }

  static void _applyLocalTyping(
    String roomId,
    String userId, {
    required bool isTyping,
  }) {
    if (isTyping) {
      _typingTimestamps.putIfAbsent(roomId, () => {});
      _typingTimestamps[roomId]![userId] = DateTime.now().add(_typingDuration);
    } else {
      _typingTimestamps[roomId]?.remove(userId);
      if (_typingTimestamps[roomId]?.isEmpty ?? false) {
        _typingTimestamps.remove(roomId);
      }
    }

    for (final listener in _listeners) {
      listener(roomId, userId, isTyping);
    }
  }

  static void _scheduleAutoStop(String roomId, String userId) {
    final key = '${roomId}_$userId';
    _autoStopTimers[key]?.cancel();
    _autoStopTimers[key] = Timer(_typingDuration, () {
      _autoStopTimers.remove(key);
      unawaited(stopTyping(roomId, userId));
    });
  }

  static void _cancelAutoStop(String roomId, String userId) {
    final key = '${roomId}_$userId';
    _autoStopTimers[key]?.cancel();
    _autoStopTimers.remove(key);
  }

  static void _scheduleRemoteCleanup(String roomId, String userId) {
    final key = '${roomId}_$userId';
    _cleanupTimers[key]?.cancel();
    _cleanupTimers[key] = Timer(_cleanupDelay, () {
      _typingTimestamps[roomId]?.remove(userId);
      if (_typingTimestamps[roomId]?.isEmpty ?? false) {
        _typingTimestamps.remove(roomId);
      }
      for (final listener in _listeners) {
        listener(roomId, userId, false);
      }
    });
  }

  static Future<void> _broadcastTyping(
    String roomId,
    String userId, {
    required bool isTyping,
  }) async {
    if (!isSupabaseConfigured()) return;

    final payload = {
      'user_id': userId,
      'is_typing': isTyping,
    };

    final subscribedChannel = _channels[roomId];
    if (subscribedChannel != null) {
      try {
        await subscribedChannel.sendBroadcastMessage(
          event: _broadcastEvent,
          payload: payload,
        );
      } catch (_) {
        // Typing is best-effort; ignore transient realtime errors.
      }
      return;
    }

    // Send-only path when the room has not been subscribed yet.
    final ephemeral = getSupabase().channel('typing_$roomId');
    try {
      ephemeral.subscribe();
      await ephemeral.sendBroadcastMessage(
        event: _broadcastEvent,
        payload: payload,
      );
    } catch (_) {
      // Typing is best-effort; ignore transient realtime errors.
    } finally {
      unawaited(ephemeral.unsubscribe());
    }
  }

  static Map<String, dynamic>? _parseBroadcastPayload(
    Map<String, dynamic> raw,
  ) {
    final inner = raw['payload'];
    if (inner is Map) {
      return Map<String, dynamic>.from(inner);
    }
    if (raw.containsKey('user_id')) {
      return raw;
    }
    return null;
  }

  static bool _parseIsTyping(Object? value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }
}
