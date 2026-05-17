import 'dart:async';

class TypingService {
  static final Map<String, Map<String, DateTime>> _typingTimestamps = {};
  static final Map<String, Timer> _cleanupTimers = {};

  static const Duration _typingDuration = Duration(seconds: 5);
  static const Duration _cleanupDelay = Duration(seconds: 7);

  static final List<void Function(String roomId, String userId, bool isTyping)> _listeners = [];

  static Future<void> startTyping(String roomId, String userId) async {
    _typingTimestamps.putIfAbsent(roomId, () => {});
    _typingTimestamps[roomId]![userId] = DateTime.now().add(_typingDuration);

    _cleanupTimers['${roomId}_$userId']?.cancel();
    _cleanupTimers['${roomId}_$userId'] = Timer(_cleanupDelay, () {
      _typingTimestamps[roomId]?.remove(userId);
      if (_typingTimestamps[roomId]?.isEmpty ?? false) {
        _typingTimestamps.remove(roomId);
      }
    });

    for (final listener in _listeners) {
      listener(roomId, userId, true);
    }
  }

  static Future<void> stopTyping(String roomId, String userId) async {
    _typingTimestamps[roomId]?.remove(userId);
    _cleanupTimers['${roomId}_$userId']?.cancel();
    _cleanupTimers.remove('${roomId}_$userId');

    for (final listener in _listeners) {
      listener(roomId, userId, false);
    }
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
    _listeners.add(listener);
  }

  static void removeListener(
    void Function(String roomId, String userId, bool isTyping) listener,
  ) {
    _listeners.remove(listener);
  }

  static void updateTypingFromRemote(
    String roomId,
    String userId,
    bool isTyping,
  ) {
    if (isTyping) {
      _typingTimestamps.putIfAbsent(roomId, () => {});
      _typingTimestamps[roomId]![userId] = DateTime.now().add(_typingDuration);
    } else {
      _typingTimestamps[roomId]?.remove(userId);
    }
    for (final listener in _listeners) {
      listener(roomId, userId, isTyping);
    }
  }

  static void dispose() {
    for (final timer in _cleanupTimers.values) {
      timer.cancel();
    }
    _cleanupTimers.clear();
    _typingTimestamps.clear();
    _listeners.clear();
  }
}
