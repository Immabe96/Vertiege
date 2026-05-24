import 'package:flutter/foundation.dart';

import '../models/resident.dart';
import 'supabase.dart';
import 'crash_reporter.dart';

class ProfileService {
  static Future<void> upsertProfile(Resident resident) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('profiles').upsert(_toClientWritableProfileRow(resident));
  }

  @visibleForTesting
  static Map<String, dynamic> clientWritableProfileRow(Resident r) =>
      _toClientWritableProfileRow(r);

  /// Fields the mobile client may write; tier/coins/streak are server/RPC managed.
  static Map<String, dynamic> _toClientWritableProfileRow(Resident r) => {
    'id': r.id,
    'name': r.name,
    'bio': r.bio,
    'avatar_url': r.avatarUrl,
    'profession': r.profession,
    'decorations': r.decorations,
    'last_check_in': r.lastCheckIn,
    'following': r.following,
    'joined_world_ids': r.joinedWorldIds,
    if (r.referredBy != null) 'referred_by': r.referredBy,
    'onboarding_completed': r.onboardingCompleted,
    'gate_completed': r.gateCompleted,
    if (r.avatarFrameId != null) 'avatar_frame_id': r.avatarFrameId,
  };

  static Future<Resident?> getProfile(String userId) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    final verifiedRoles = await _getVerifiedRoles(userId);
    final joinedWorldIds = await _getJoinedWorldIds(userId, data);
    return _toResident(
      data,
      verifiedRoles: verifiedRoles,
      joinedWorldIds: joinedWorldIds,
    );
  }

  static Future<List<Resident>> searchResidents(
    String query, {
    int limit = 20,
  }) async {
    if (!isSupabaseConfigured()) return [];
    // Strip characters that could interfere with PostgREST filter syntax
    final safe = query.replaceAll(RegExp(r'[%,.*()]'), '');
    if (safe.isEmpty) return [];
    final client = getSupabase();
    final data = await client
        .from('profiles')
        .select()
        .or('name.ilike.%$safe%,profession.ilike.%$safe%')
        .limit(limit);
    return (data as List).map((e) => _toResident(e)).toList();
  }

  static Future<List<Resident>> getTopResidents({int limit = 5}) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('profiles')
        .select()
        .order('tier', ascending: false)
        .order('streak_count', ascending: false)
        .limit(limit);
    return (data as List).map((e) => _toResident(e)).toList();
  }

  static Map<String, dynamic> _toProfileRow(Resident r) => {
    'id': r.id,
    'name': r.name,
    'bio': r.bio,
    'tier': r.tier.value,
    'avatar_url': r.avatarUrl,
    'profession': r.profession,
    'decorations': r.decorations,
    'last_check_in': r.lastCheckIn,
    'streak_count': r.streakCount,
    'streak_shields': r.streakShields,
    'following': r.following,
    'joined_world_ids': r.joinedWorldIds,
    if (r.referredBy != null) 'referred_by': r.referredBy,
    'sovereign_coins': r.sovereignCoins,
    'onboarding_completed': r.onboardingCompleted,
    'gate_completed': r.gateCompleted,
    if (r.avatarFrameId != null) 'avatar_frame_id': r.avatarFrameId,
  };

  static Resident _toResident(
    Map<String, dynamic> data, {
    List<String> verifiedRoles = const [],
    List<String>? joinedWorldIds,
  }) => Resident(
    id: data['id'] ?? '',
    name: data['name'] ?? 'Member',
    tier: ResidentTier.fromValue(data['tier'] ?? 1),
    bio: data['bio'] ?? '',
    avatarUrl: data['avatar_url'] ?? '',
    profession: data['profession'],
    verifiedRoles: verifiedRoles,
    decorations: List<String>.from(data['decorations'] ?? []),
    lastCheckIn: data['last_check_in'] as String?,
    streakCount: (data['streak_count'] as int?) ?? 0,
    streakShields: (data['streak_shields'] as int?) ?? 0,
    following: List<String>.from(data['following'] ?? []),
    joinedWorldIds:
        joinedWorldIds ?? List<String>.from(data['joined_world_ids'] ?? []),
    referredBy: data['referred_by'] as String?,
    sovereignCoins: (data['sovereign_coins'] as int?) ?? 100,
    onboardingCompleted: data['onboarding_completed'] ?? false,
    gateCompleted: data['gate_completed'] ?? false,
    avatarFrameId: data['avatar_frame_id'] as String?,
  );

  static Future<List<String>> _getVerifiedRoles(String userId) async {
    try {
      final client = getSupabase();
      final data = await client
          .from('verification_submissions')
          .select('profession')
          .eq('resident_id', userId)
          .eq('status', 'verified');
      return (data as List)
          .map((e) => (e as Map<String, dynamic>)['profession']?.toString())
          .whereType<String>()
          .toSet()
          .toList();
    } catch (e, st) {
      // Graceful degradation — profile loads without verified roles.
      CrashReporter.instance.recordError(
        e,
        st,
        hint: 'profile_service getVerifiedRoles',
      );
      return const [];
    }
  }

  static Future<List<String>> _getJoinedWorldIds(
    String userId,
    Map<String, dynamic> profile,
  ) async {
    return List<String>.from(profile['joined_world_ids'] ?? []);
  }
}
