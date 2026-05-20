import 'supabase.dart';
import '../models/notification.dart';
import 'crash_reporter.dart';

/// Service for synchronizing notifications with the Supabase backend.
class NotificationService {
  NotificationService._();

  /// Fetches the latest 50 notifications for a given user.
  static Future<List<AppNotification>> getNotifications(
    String recipientId,
  ) async {
    if (!isSupabaseConfigured()) return [];

    final client = getSupabase();
    final data = await client
        .from('notifications')
        .select()
        .eq('recipient_id', recipientId)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List)
        .map(
          (json) => AppNotification.fromSupabase(json as Map<String, dynamic>),
        )
        .toList();
  }

  /// Marks a specific notification as read in the database.
  static Future<void> markRead(String notificationId) async {
    if (!isSupabaseConfigured()) return;

    try {
      await getSupabase()
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (error, stackTrace) {
      CrashReporter.instance.recordError(
        error,
        stackTrace,
        hint: 'notification mark read',
      );
      rethrow;
    }
  }

  /// Marks all unread notifications as read for a given user.
  static Future<void> markAllRead(String recipientId) async {
    if (!isSupabaseConfigured()) return;

    try {
      await getSupabase()
          .from('notifications')
          .update({'read': true})
          .eq('recipient_id', recipientId)
          .eq('read', false);
    } catch (error, stackTrace) {
      CrashReporter.instance.recordError(
        error,
        stackTrace,
        hint: 'notification mark all read',
      );
      rethrow;
    }
  }

  /// Creates a new notification record in Supabase.
  /// Typically called from server-side or during social interactions.
  static Future<void> createNotification({
    required String recipientId,
    required AppNotification notification,
  }) async {
    if (!isSupabaseConfigured()) return;

    try {
      await getSupabase()
          .from('notifications')
          .insert(notification.toSupabase(recipientId));
    } catch (error, stackTrace) {
      CrashReporter.instance.recordError(
        error,
        stackTrace,
        hint: 'notification create',
      );
      rethrow;
    }
  }
}
