import '../models/invite.dart';
import '../utils/id_generator.dart';
import 'supabase.dart';

class InviteService {
  static Future<WorldInvite?> createInvite({
    required String worldId,
    required String createdBy,
    int maxUses = 0,
    int? expiresAt,
  }) async {
    final invite = {
      'id': generateId(),
      'world_id': worldId,
      'code': _generateCode(),
      'created_by': createdBy,
      'max_uses': maxUses,
      'uses': 0,
      'expires_at': expiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(expiresAt).toIso8601String()
          : null,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (!isSupabaseConfigured()) {
      return _toInvite(invite);
    }

    final client = getSupabase();
    await client.from('world_invites').insert(invite);
    return _toInvite(invite);
  }

  static Future<WorldInvite?> validateInvite(String code) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('world_invites')
        .select()
        .eq('code', code)
        .maybeSingle();
    if (data == null) return null;
    return _toInvite(data);
  }

  static Future<bool> acceptInvite(String inviteId, String worldId, String residentId) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();

    // Increment uses
    final current = await client
        .from('world_invites')
        .select('uses')
        .eq('id', inviteId)
        .maybeSingle();
    final newUses = ((current?['uses'] as int?) ?? 0) + 1;
    await client.from('world_invites').update({'uses': newUses}).eq('id', inviteId);

    // Add resident to world members
    await client.from('world_members').upsert({
      'id': '${worldId}_$residentId',
      'world_id': worldId,
      'resident_id': residentId,
      'standing': 1,
      'rep': 0,
      'joined_at': DateTime.now().toIso8601String(),
    });

    return true;
  }

  static Future<List<WorldInvite>> getInvitesForWorld(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('world_invites')
        .select()
        .eq('world_id', worldId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => _toInvite(e)).toList();
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final code = List.generate(6, (_) => chars[DateTime.now().microsecondsSinceEpoch % chars.length]).join();
    return code;
  }

  static WorldInvite _toInvite(Map<String, dynamic> data) => WorldInvite(
        id: data['id'] ?? '',
        worldId: data['world_id'] ?? '',
        code: data['code'] ?? '',
        createdBy: data['created_by'] ?? '',
        maxUses: data['max_uses'] ?? 0,
        uses: data['uses'] ?? 0,
        expiresAt: data['expires_at'] != null
            ? DateTime.tryParse(data['expires_at'].toString())?.millisecondsSinceEpoch
            : null,
        createdAt: DateTime.tryParse(data['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0,
      );
}
