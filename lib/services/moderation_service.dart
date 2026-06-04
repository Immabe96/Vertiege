import '../utils/id_generator.dart';
import 'supabase.dart';

class ModerationService {
  // ── Realm Audit ──────────────────────────────────────────

  static Future<void> logAudit({
    required String worldId,
    required String actorId,
    String? targetId,
    required String action,
    Map<String, dynamic>? details,
  }) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('world_audit_log').insert({
      'id': generateId(),
      'world_id': worldId,
      'actor_id': actorId,
      'target_id': targetId,
      'action': action,
      'details': details ?? {},
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, String>> resolveActorNames(
    Iterable<String> actorIds,
  ) async {
    final unique = actorIds.where((id) => id.isNotEmpty).toSet().toList();
    if (!isSupabaseConfigured() || unique.isEmpty) return {};
    final data = await getSupabase()
        .from('profiles')
        .select('id, name')
        .inFilter('id', unique);
    final map = <String, String>{};
    for (final row in data as List) {
      final m = row as Map<String, dynamic>;
      final id = m['id'] as String?;
      if (id == null) continue;
      map[id] = (m['name'] as String?)?.trim().isNotEmpty == true
          ? (m['name'] as String).trim()
          : 'Resident';
    }
    return map;
  }

  static Future<List<Map<String, dynamic>>> getAuditLog(
    String worldId, {
    int limit = 100,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('world_audit_log')
        .select()
        .eq('world_id', worldId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }

  // ── Bulk message deletion ───────────────────────────────

  static Future<void> bulkDeleteMessages({
    required List<String> messageIds,
    required String actorId,
    required String worldId,
  }) async {
    if (!isSupabaseConfigured() || messageIds.isEmpty) return;
    final client = getSupabase();
    await client.from('channel_messages').delete().inFilter('id', messageIds);
    await logAudit(
      worldId: worldId,
      actorId: actorId,
      action: 'bulkDelete',
      details: {'count': messageIds.length, 'message_ids': messageIds},
    );
  }

  // ── Moderation actions ──────────────────────────────────

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
