class RateLimiter {
  static final Map<String, List<int>> _timestamps = {};
  static final Map<String, int> _limits = {};

  static bool canProceed(
    String key, {
    int windowMs = 1000,
    int maxCalls = 5,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _timestamps.putIfAbsent(key, () => []);

    final effectiveMax = _limits[key] ?? maxCalls;
    final cutoff = now - windowMs;
    _timestamps[key] = _timestamps[key]!
        .where((ts) => ts > cutoff)
        .toList();

    if (_timestamps[key]!.length >= effectiveMax) {
      return false;
    }

    _timestamps[key]!.add(now);
    return true;
  }

  static void setLimit(String key, int maxCalls) {
    _limits[key] = maxCalls;
  }

  static void clear() {
    _timestamps.clear();
    _limits.clear();
  }
}
