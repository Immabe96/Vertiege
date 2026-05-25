import '../config/achievements.dart' as ach_config;
import '../models/achievement.dart';
import '../utils/achievement_proof_utils.dart';
import 'gamification_service.dart';
import 'supabase.dart';

class PendingAchievementSubmission {
  final String userId;
  final String residentName;
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
    required this.achievementId,
    required this.achievementTitle,
    this.achievementDescription,
    this.proofUris = const [],
    this.aiNotes,
    this.aiConfidence,
    this.submittedAt,
  });
}

class AchievementReviewService {
  static Achievement? _definition(String achievementId) {
    return ach_config.achievements
        .where((a) => a.id == achievementId)
        .firstOrNull;
  }

  static Future<List<PendingAchievementSubmission>> getPending() async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('user_achievements')
        .select(
          'user_id, achievement_id, proof_uri, proof_uris, ai_notes, ai_confidence, submitted_at, profiles(name)',
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
