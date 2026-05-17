import '../models/ally.dart';
import '../models/notification.dart';
import '../utils/id_generator.dart';
import 'notification_service.dart';
import 'supabase.dart';

class AllyService {
  static Future<void> sendAllegianceRequest({
    required String requesterId,
    required String receiverId,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();

    final existing = await client
        .from('allies')
        .select()
        .or('requester_id.eq.$requesterId,requester_id.eq.$receiverId')
        .or('receiver_id.eq.$requesterId,receiver_id.eq.$receiverId')
        .maybeSingle();

    if (existing != null) return;

    await client.from('allies').insert({
      'id': generateId(),
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });

    final notification = AppNotification(
      id: generateId(),
      type: NotificationType.allegianceRequest,
      message: 'You received a new allegiance request',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await NotificationService.createNotification(
      recipientId: receiverId,
      notification: notification,
    );
  }

  static Future<void> acceptAllegianceRequest(String requestId) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase()
        .from('allies')
        .update({'status': 'accepted'})
        .eq('id', requestId);
  }

  static Future<void> declineAllegianceRequest(String requestId) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase().from('allies').delete().eq('id', requestId);
  }

  static Future<void> blockResident(String requestId) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase()
        .from('allies')
        .update({'status': 'blocked'})
        .eq('id', requestId);
  }

  static Future<List<Ally>> fetchAllies(String residentId) async {
    if (!isSupabaseConfigured()) return [];
    final data = await getSupabase()
        .from('allies')
        .select()
        .or('requester_id.eq.$residentId,receiver_id.eq.$residentId')
        .eq('status', 'accepted');
    return (data as List)
        .map((e) => Ally.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<Ally>> fetchPendingRequests(String residentId) async {
    if (!isSupabaseConfigured()) return [];
    final data = await getSupabase()
        .from('allies')
        .select()
        .eq('receiver_id', residentId)
        .eq('status', 'pending');
    return (data as List)
        .map((e) => Ally.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Ally?> getRelationship(
    String residentId,
    String otherResidentId,
  ) async {
    if (!isSupabaseConfigured()) return null;
    final data = await getSupabase()
        .from('allies')
        .select()
        .or(
          'and(requester_id.eq.$residentId,receiver_id.eq.$otherResidentId),'
          'and(requester_id.eq.$otherResidentId,receiver_id.eq.$residentId)',
        )
        .maybeSingle();
    if (data == null) return null;
    return Ally.fromSupabase(data);
  }
}
