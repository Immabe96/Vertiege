import '../utils/id_generator.dart';
import 'supabase.dart';

/// Service for server-side moderation actions (ban, mute, warn).
/// Persists all actions to the Supabase `moderation_logs` table so they
/// are enforced globally, not just on the moderator's device.
class ModerationService {
  /// Record a ban and remove the user from the world.
  static Future<void> banUser({
    required String worldId,
    required String moderatorId,
    required String targetUserId,
    String? reason,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();

    // 1. Log the moderation action
    await client.from('moderation_logs').insert({
      'id': generateId(),
      'world_id': worldId,
      'moderator_id': moderatorId,
      'target_user_id': targetUserId,
      'action': 'ban',
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 2. Remove the user from the world
    await client
        .from('world_members')
        .delete()
        .eq('world_id', worldId)
        .eq('resident_id', targetUserId);
  }

  /// Remove a ban.
  static Future<void> unbanUser({
    required String worldId,
    required String moderatorId,
    required String targetUserId,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();

    await client.from('moderation_logs').insert({
      'id': generateId(),
      'world_id': worldId,
      'moderator_id': moderatorId,
      'target_user_id': targetUserId,
      'action': 'unban',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Mute a user for [durationHours] hours.
  static Future<void> muteUser({
    required String worldId,
    required String moderatorId,
    required String targetUserId,
    required int durationHours,
    String? reason,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();

    await client.from('moderation_logs').insert({
      'id': generateId(),
      'world_id': worldId,
      'moderator_id': moderatorId,
      'target_user_id': targetUserId,
      'action': 'mute',
      'reason': reason,
      'duration_hours': durationHours,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Unmute a user.
  static Future<void> unmuteUser({
    required String worldId,
    required String moderatorId,
    required String targetUserId,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();

    await client.from('moderation_logs').insert({
      'id': generateId(),
      'world_id': worldId,
      'moderator_id': moderatorId,
      'target_user_id': targetUserId,
      'action': 'unmute',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Check if a user is currently banned in a world.
  /// Looks at the latest ban/unban log entry.
  static Future<bool> isBanned(String worldId, String userId) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();

    final data = await client
        .from('moderation_logs')
        .select()
        .eq('world_id', worldId)
        .eq('target_user_id', userId)
        .inFilter('action', ['ban', 'unban'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return false;
    return data['action'] == 'ban';
  }

  /// Check if a user is currently muted in a world.
  /// A mute is active if the latest mute log + duration_hours is still in the future.
  static Future<bool> isMuted(String worldId, String userId) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();

    final data = await client
        .from('moderation_logs')
        .select()
        .eq('world_id', worldId)
        .eq('target_user_id', userId)
        .inFilter('action', ['mute', 'unmute'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return false;
    if (data['action'] == 'unmute') return false;

    final createdAt = DateTime.tryParse(data['created_at'] ?? '');
    final durationHours = data['duration_hours'] as int? ?? 0;
    if (createdAt == null) return false;

    final expiresAt = createdAt.add(Duration(hours: durationHours));
    return DateTime.now().isBefore(expiresAt);
  }

  /// Submit a report against a post.
  static Future<void> submitReport({
    required String worldId,
    required String postId,
    required String reporterId,
    required String reason,
    String? details,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('reports').insert({
      'id': generateId(),
      'world_id': worldId,
      'post_id': postId,
      'reporter_id': reporterId,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get pending reports for a world (moderation dashboard).
  static Future<List<Map<String, dynamic>>> getReports(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('reports')
        .select()
        .eq('world_id', worldId)
        .order('created_at', ascending: false)
        .limit(50);
    return (data as List).cast<Map<String, dynamic>>();
  }

  /// Get full moderation history for a world.
  static Future<List<Map<String, dynamic>>> getWorldLogs(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('moderation_logs')
        .select()
        .eq('world_id', worldId)
        .order('created_at', ascending: false)
        .limit(100);
    return (data as List).cast<Map<String, dynamic>>();
  }
}
