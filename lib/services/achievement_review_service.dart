import '../config/achievements.dart' as ach_config;
import '../models/achievement.dart';
import 'supabase.dart';

class PendingAchievementSubmission {
  final String userId;
  final String residentName;
  final String achievementId;
  final String achievementTitle;
  final String? proofUri;
  final String? aiNotes;
  final double? aiConfidence;
  final DateTime? submittedAt;

  const PendingAchievementSubmission({
    required this.userId,
    required this.residentName,
    required this.achievementId,
    required this.achievementTitle,
    this.proofUri,
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
        .select('user_id, achievement_id, proof_uri, ai_notes, ai_confidence, submitted_at, profiles(name)')
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
        proofUri: map['proof_uri'] as String?,
        aiNotes: map['ai_notes'] as String?,
        aiConfidence: (map['ai_confidence'] as num?)?.toDouble(),
        submittedAt: DateTime.tryParse(map['submitted_at']?.toString() ?? ''),
      );
    }).toList();
  }

  static Future<void> approve({
    required String userId,
    required String achievementId,
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to approve achievements.');
    }
    final now = DateTime.now().toIso8601String();
    await getSupabase()
        .from('user_achievements')
        .update({
          'status': 'verified',
          'verified_at': now,
        })
        .eq('user_id', userId)
        .eq('achievement_id', achievementId);
  }

  static Future<void> reject({
    required String userId,
    required String achievementId,
    String? notes,
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to reject achievements.');
    }
    await getSupabase()
        .from('user_achievements')
        .update({
          'status': 'rejected',
          if (notes != null && notes.isNotEmpty) 'ai_notes': notes,
        })
        .eq('user_id', userId)
        .eq('achievement_id', achievementId);
  }
}
