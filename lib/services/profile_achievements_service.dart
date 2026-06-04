import '../config/achievements.dart' as ach_config;
import '../models/achievement.dart';
import '../utils/achievement_proof_utils.dart';
import 'profile_service.dart';
import 'supabase.dart';

/// Verified achievements visible on a resident's public profile.
class PublicAchievementEntry {
  final Achievement achievement;
  final UserAchievement userAchievement;
  final int? featuredOrder;
  final String? story;

  const PublicAchievementEntry({
    required this.achievement,
    required this.userAchievement,
    this.featuredOrder,
    this.story,
  });
}

class ProfileAchievementsService {
  ProfileAchievementsService._();

  static Future<List<PublicAchievementEntry>> fetchPublicProfile(
    String residentId,
  ) async {
    if (!isSupabaseConfigured() || residentId.isEmpty) return [];
    final featuredIds =
        await ProfileService.getFeaturedAchievementIds(residentId);
    final rows = await getSupabase()
        .from('user_achievements')
        .select(
          'achievement_id, status, proof_uri, proof_uris, verified_at, is_profile_visible, featured_order, achievement_story',
        )
        .eq('user_id', residentId)
        .eq('status', 'verified')
        .eq('is_profile_visible', true);

    final entries = <PublicAchievementEntry>[];
    for (final row in rows as List) {
      final map = row as Map<String, dynamic>;
      final id = map['achievement_id'] as String? ?? '';
      final def = ach_config.achievementForId(id);
      if (def == null) continue;
      final featuredIdx = featuredIds.indexOf(id);
      final legacyOrder = (map['featured_order'] as num?)?.toInt();
      entries.add(
        PublicAchievementEntry(
          achievement: def,
          userAchievement: UserAchievement(
            achievementId: id,
            status: AchievementStatus.verified,
            proofUris: parseProofUris(
              proofUri: map['proof_uri'] as String?,
              proofUrisRaw: map['proof_uris'],
            ),
            verifiedAt: _parseMillis(map['verified_at']),
          ),
          featuredOrder: featuredIdx >= 0
              ? featuredIdx + 1
              : legacyOrder,
          story: map['achievement_story'] as String?,
        ),
      );
    }

    entries.sort((a, b) {
      final fa = a.featuredOrder;
      final fb = b.featuredOrder;
      if (fa != null && fb != null) return fa.compareTo(fb);
      if (fa != null) return -1;
      if (fb != null) return 1;
      return (b.userAchievement.verifiedAt ?? 0)
          .compareTo(a.userAchievement.verifiedAt ?? 0);
    });
    return entries;
  }

  static Future<void> setProfileVisibility({
    required String achievementId,
    required bool visible,
    int? featuredOrder,
    bool clearFeaturedOrder = false,
  }) async {
    if (!isSupabaseConfigured()) return;
    final userId = maybeSupabase()?.auth.currentUser?.id;
    if (userId == null) return;
    final data = <String, dynamic>{'is_profile_visible': visible};
    if (clearFeaturedOrder) {
      data['featured_order'] = null;
    } else if (featuredOrder != null) {
      data['featured_order'] = featuredOrder;
    }
    await getSupabase()
        .from('user_achievements')
        .update(data)
        .eq('user_id', userId)
        .eq('achievement_id', achievementId);
  }

  static int? _parseMillis(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch;
    }
    return null;
  }
}
