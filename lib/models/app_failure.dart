/// Structured error representation for repository and service failures.
///
/// Replaces raw Exception/String error handling with typed failures
/// that the UI can pattern-match for appropriate user messaging.
enum AppFailureType {
  network,
  auth,
  permission,
  notFound,
  validation,
  rateLimited,
  server,
  unknown,
}

class AppFailure implements Exception {
  final AppFailureType type;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const AppFailure({
    required this.type,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  factory AppFailure.network([String? message]) => AppFailure(
        type: AppFailureType.network,
        message: message ?? 'No internet connection',
      );

  factory AppFailure.auth([String? message]) => AppFailure(
        type: AppFailureType.auth,
        message: message ?? 'Authentication required',
      );

  factory AppFailure.permission([String? message]) => AppFailure(
        type: AppFailureType.permission,
        message: message ?? 'You do not have permission',
      );

  factory AppFailure.notFound([String? message]) => AppFailure(
        type: AppFailureType.notFound,
        message: message ?? 'Not found',
      );

  factory AppFailure.validation(String message) => AppFailure(
        type: AppFailureType.validation,
        message: message,
      );

  factory AppFailure.rateLimited([String? message]) => AppFailure(
        type: AppFailureType.rateLimited,
        message: message ?? 'Too many requests. Please wait.',
      );

  factory AppFailure.server([String? message]) => AppFailure(
        type: AppFailureType.server,
        message: message ?? 'Server error. Try again.',
      );

  factory AppFailure.fromException(Object error, [StackTrace? stackTrace]) {
    if (error is AppFailure) return error;
    return AppFailure(
      type: AppFailureType.unknown,
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  bool get isNetwork => type == AppFailureType.network;
  bool get isAuth => type == AppFailureType.auth;
  bool get isPermission => type == AppFailureType.permission;
  bool get isNotFound => type == AppFailureType.notFound;
  bool get isRateLimited => type == AppFailureType.rateLimited;
  bool get isRetryable => type == AppFailureType.network || type == AppFailureType.server;

  @override
  String toString() => 'AppFailure($type): $message';
}
