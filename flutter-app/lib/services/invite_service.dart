import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invite.dart';
import '../utils/id_generator.dart';
import 'supabase.dart';

class InviteRedeemResult {
  final String? worldId;
  final String? errorMessage;

  const InviteRedeemResult({this.worldId, this.errorMessage});

  bool get succeeded => worldId != null;
}

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

  static Future<String?> _consumePendingCode() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_pendingInviteCodeKey);
    if (code == null || code.trim().isEmpty) return null;
    await prefs.remove(_pendingInviteCodeKey);
    return code.trim();
  }

  /// Accepts a saved invite code after onboarding and returns the joined world.
  static Future<InviteRedeemResult> redeemPendingInvite({
    required String residentId,
    required String residentName,
  }) async {
    final code = await _consumePendingCode();
    if (code == null) return const InviteRedeemResult();
    return redeemInviteCode(
      code: code,
      residentId: residentId,
      residentName: residentName,
    );
  }

  /// Validates and accepts an invite code without persisting it.
  static Future<InviteRedeemResult> redeemInviteCode({
    required String code,
    required String residentId,
    required String residentName,
  }) async {
    if (!isSupabaseConfigured()) {
      return const InviteRedeemResult(
        errorMessage: 'Sign in to accept this invite.',
      );
    }

    final invite = await validateInvite(code);
    if (invite == null || !invite.isValid) {
      return const InviteRedeemResult(
        errorMessage: 'Invalid or expired invite code.',
      );
    }

    await acceptInvite(
      invite.id,
      invite.worldId,
      residentId,
      residentName: residentName,
    );
    return InviteRedeemResult(worldId: invite.worldId);
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
    final invite = _toInvite(data);
    if (!invite.isValid) return null;
    return invite;
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

    // Fetch current invite state to validate expiry and usage
    final invite = await client
        .from('invites')
        .select('uses,max_uses,expires_at')
        .eq('id', inviteId)
        .maybeSingle();

    if (invite == null) return false;

    final uses = invite['uses'] as int? ?? 0;
    final maxUses = invite['max_uses'] as int? ?? 0;
    final expiresAt = invite['expires_at'] as int?;

    if (maxUses > 0 && uses >= maxUses) return false;
    if (expiresAt != null && DateTime.now().millisecondsSinceEpoch > expiresAt) {
      return false;
    }

    // Increment uses
    await client
        .from('invites')
        .update({'uses': uses + 1})
        .eq('id', inviteId)
        .eq('uses', uses);

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
    return (data as List).cast<Map<String, dynamic>>().map(_toInvite).toList();
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
    id: data['id']?.toString() ?? '',
    worldId: data['world_id']?.toString() ?? '',
    code: data['code']?.toString() ?? '',
    createdBy: data['created_by']?.toString() ?? '',
    maxUses: data['max_uses'] as int? ?? 0,
    uses: data['uses'] as int? ?? 0,
    expiresAt: data['expires_at'] != null
        ? DateTime.tryParse(
            data['expires_at'].toString(),
          )?.millisecondsSinceEpoch
        : null,
    createdAt:
        DateTime.tryParse(data['created_at']?.toString() ?? '')?.millisecondsSinceEpoch ??
        0,
  );
}
