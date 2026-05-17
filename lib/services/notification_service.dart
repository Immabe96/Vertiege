import 'supabase.dart';
import '../models/notification.dart';

/// Service for synchronizing notifications with the Supabase backend.
class NotificationService {
  NotificationService._();

  /// Fetches the latest 50 notifications for a given user.
  static Future<List<AppNotification>> getNotifications(
    String recipientId,
  ) async {
    if (!isSupabaseConfigured()) return [];

    try {
      final client = getSupabase();
      final data = await client
          .from('notifications')
          .select()
          .eq('recipient_id', recipientId)
          .order('created_at', ascending: false)
          .limit(50);

      return (data as List)
          .map(
            (json) =>
                AppNotification.fromSupabase(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      // Log error or handle gracefully
      return [];
    }
  }

  /// Marks a specific notification as read in the database.
  static Future<void> markRead(String notificationId) async {
    if (!isSupabaseConfigured()) return;

    try {
      final client = getSupabase();
      await client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (e) {
      // Log error
    }
  }

  /// Marks all unread notifications as read for a given user.
  static Future<void> markAllRead(String recipientId) async {
    if (!isSupabaseConfigured()) return;

    try {
      final client = getSupabase();
      await client
          .from('notifications')
          .update({'read': true})
          .eq('recipient_id', recipientId)
          .eq('read', false);
    } catch (e) {
      // Log error
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
      final client = getSupabase();
      await client
          .from('notifications')
          .insert(notification.toSupabase(recipientId));
    } catch (e) {
      // Log error
    }
  }
}
