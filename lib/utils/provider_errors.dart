import '../models/app_failure.dart';

/// User-readable copy for provider [catch] blocks — avoids raw exception dumps in UI.
String userFacingLoadError(
  Object error, {
  String fallback = 'Something went wrong. Pull to refresh.',
}) {
  if (error is AppFailure) return error.message;

  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('network') ||
      text.contains('connection') ||
      text.contains('offline')) {
    return 'No connection. Check your network and try again.';
  }
  if (text.contains('timeout')) {
    return 'Request timed out. Try again.';
  }
  if (text.contains('401') || text.contains('unauthorized')) {
    return 'Session expired. Sign in again.';
  }
  if (text.contains('403') || text.contains('permission')) {
    return 'You do not have permission for this action.';
  }
  return fallback;
}
