import '../config/achievements.dart' as ach_config;
import '../models/achievement.dart';
import '../utils/achievement_proof_utils.dart';
import 'gamification_service.dart';
import 'supabase.dart';

class PendingAchievementSubmission {
  final String userId;
  final String residentName;
  final int residentTotalXp;
  final String achievementId;
  final String achievementTitle;
  final String? achievementDescription;
  final List<String> proofUris;
  final String? aiNotes;
  final double? aiConfidence;
  final DateTime? submittedAt;

  const PendingAchievementSubmission({
    required this.userId,
    required this.residentName,
    this.residentTotalXp = 0,
    required this.achievementId,
    required this.achievementTitle,
    this.achievementDescription,
    this.proofUris = const [],
    this.aiNotes,
    this.aiConfidence,
    this.submittedAt,
  });
}

/// Prior rejections for the same resident (verifier context).
class ResidentReviewHistoryEntry {
  final String achievementId;
  final String achievementTitle;
  final String? reviewerNotes;
  final DateTime? submittedAt;

  const ResidentReviewHistoryEntry({
    required this.achievementId,
    required this.achievementTitle,
    this.reviewerNotes,
    this.submittedAt,
  });
}

class ResidentReviewHistory {
  final int rejectedCount;
  final int verifiedCount;
  final List<ResidentReviewHistoryEntry> recentRejections;

  const ResidentReviewHistory({
    this.rejectedCount = 0,
    this.verifiedCount = 0,
    this.recentRejections = const [],
  });

  bool get hasPriorRejections => rejectedCount > 0;
}

class AchievementReviewService {
  static Achievement? _definition(String achievementId) =>
      ach_config.achievementForId(achievementId);

  static Future<List<PendingAchievementSubmission>> getPending() async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('user_achievements')
        .select(
          'user_id, achievement_id, proof_uri, proof_uris, ai_notes, ai_confidence, submitted_at, profiles(name, total_xp)',
        )
        .eq('status', 'submitted')
        .order('submitted_at', ascending: false);

    return (data as List).map((row) {
      final map = row as Map<String, dynamic>;
      final profile = map['profiles'] as Map<String, dynamic>?;
      final achievementId = map['achievement_id'] as String? ?? '';
      final def = _definition(achievementId);
      return PendingAchievementSubmission(
        userId: map['user_id'] as String? ?? '',
        residentName: profile?['name'] as String? ?? 'Member',
        residentTotalXp: (profile?['total_xp'] as num?)?.toInt() ?? 0,
        achievementId: achievementId,
        achievementTitle: def?.title ?? achievementId,
        achievementDescription: def?.description,
        proofUris: parseProofUris(
          proofUri: map['proof_uri'] as String?,
          proofUrisRaw: map['proof_uris'],
        ),
        aiNotes: map['ai_notes'] as String?,
        aiConfidence: (map['ai_confidence'] as num?)?.toDouble(),
        submittedAt: DateTime.tryParse(map['submitted_at']?.toString() ?? ''),
      );
    }).toList();
  }

  static Future<void> approve({
    required String userId,
    required String achievementId,
    String? reviewerNotes,
  }) async {
    await GamificationService.grantVerifiedAchievement(
      userId: userId,
      achievementId: achievementId,
      reviewerNotes: reviewerNotes,
    );
  }

  static Future<ResidentReviewHistory> getResidentReviewHistory(
    String userId,
  ) async {
    if (!isSupabaseConfigured() || userId.isEmpty) {
      return const ResidentReviewHistory();
    }
    final client = getSupabase();
    final data = await client
        .from('user_achievements')
        .select('achievement_id, status, ai_notes, submitted_at')
        .eq('user_id', userId)
        .or('status.eq.rejected,status.eq.verified')
        .order('submitted_at', ascending: false)
        .limit(24);

    var rejected = 0;
    var verified = 0;
    final rejections = <ResidentReviewHistoryEntry>[];

    for (final row in data as List) {
      final map = row as Map<String, dynamic>;
      final status = map['status'] as String? ?? '';
      final achievementId = map['achievement_id'] as String? ?? '';
      final def = _definition(achievementId);
      if (status == 'verified') {
        verified++;
        continue;
      }
      if (status == 'rejected') {
        rejected++;
        if (rejections.length < 5) {
          rejections.add(
            ResidentReviewHistoryEntry(
              achievementId: achievementId,
              achievementTitle: def?.title ?? achievementId,
              reviewerNotes: map['ai_notes'] as String?,
              submittedAt: DateTime.tryParse(
                map['submitted_at']?.toString() ?? '',
              ),
            ),
          );
        }
      }
    }

    return ResidentReviewHistory(
      rejectedCount: rejected,
      verifiedCount: verified,
      recentRejections: rejections,
    );
  }

  static Future<void> reject({
    required String userId,
    required String achievementId,
    String? notes,
  }) async {
    await GamificationService.rejectAchievementSubmission(
      userId: userId,
      achievementId: achievementId,
      reviewerNotes: notes,
    );
  }
}
