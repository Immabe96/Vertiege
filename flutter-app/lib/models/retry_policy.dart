/// Configures retry behavior for mutation outbox items.
class RetryPolicy {
  /// Maximum number of retry attempts before surfacing as failed.
  final int maxRetries;

  /// Base delay between retries (exponential backoff: delay * 2^attempt).
  final Duration baseDelay;

  /// Maximum delay cap.
  final Duration maxDelay;

  /// Whether to retry on network errors only, or all errors.
  final bool retryNetworkOnly;

  const RetryPolicy({
    this.maxRetries = 5,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
    this.retryNetworkOnly = true,
  });

  /// Default policy suitable for most mutations.
  static const standard = RetryPolicy();

  /// Aggressive retry for time-sensitive mutations (messages, reactions).
  static const fast = RetryPolicy(
    maxRetries: 3,
    baseDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 30),
  );

  /// Conservative retry for expensive mutations (media uploads).
  static const slow = RetryPolicy(
    maxRetries: 3,
    baseDelay: Duration(seconds: 10),
    maxDelay: Duration(minutes: 10),
  );

  Duration delayForAttempt(int attempt) {
    final raw = baseDelay * (1 << attempt);
    return raw > maxDelay ? maxDelay : raw;
  }

  bool shouldRetry(int attempts, {required bool isNetworkError}) {
    if (attempts >= maxRetries) return false;
    if (retryNetworkOnly && !isNetworkError) return false;
    return true;
  }
}
