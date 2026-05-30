import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invite.dart';
import '../utils/id_generator.dart';
import 'supabase.dart';

class InviteService {
  static const _pendingInviteCodeKey = 'pending_invite_code';

  static String inviteDeepLink(String code) =>
      'vertiege://invite/${Uri.encodeComponent(code)}';

  static String invitePath(String code) => '/invite/${Uri.encodeComponent(code)}';

  static Future<void> savePendingInviteCode(String code) async {
    final normalized = code.trim();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingInviteCodeKey, normalized);
  }

  static Future<String?> takePendingInvitePath() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_pendingInviteCodeKey);
    if (code == null || code.trim().isEmpty) return null;
    await prefs.remove(_pendingInviteCodeKey);
    return invitePath(code);
  }

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
      'expires_at': expiresAt,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to create invites.');
    }

    final client = getSupabase();
    await client.from('invites').insert(invite);
    return _toInvite(invite);
  }

  static Future<WorldInvite?> validateInvite(String code) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('invites')
        .select()
        .eq('code', code)
        .maybeSingle();
    if (data == null) return null;
    return _toInvite(data);
  }

  static Future<bool> acceptInvite(
    String inviteId,
    String worldId,
    String residentId, {
    String residentName = 'Member',
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to accept invites.');
    }
    final client = getSupabase();

    // Increment uses
    final current = await client
        .from('invites')
        .select('uses')
        .eq('id', inviteId)
        .maybeSingle();
    final newUses = ((current?['uses'] as int?) ?? 0) + 1;
    await client.from('invites').update({'uses': newUses}).eq('id', inviteId);

    // Add resident to world members
    try {
      await client.from('world_members').insert({
        'world_id': worldId,
        'resident_id': residentId,
        'resident_name': residentName,
        'rep': 0,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow;
    }

    return true;
  }

  static Future<List<WorldInvite>> getInvitesForWorld(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('invites')
        .select()
        .eq('world_id', worldId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => _toInvite(e)).toList();
  }

  static String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    final code = List.generate(
      6,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
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
        ? DateTime.tryParse(
            data['expires_at'].toString(),
          )?.millisecondsSinceEpoch
        : null,
    createdAt:
        DateTime.tryParse(data['created_at'] ?? '')?.millisecondsSinceEpoch ??
        0,
  );
}
