import 'package:flutter/foundation.dart';

import 'supabase.dart';

/// Server-side achievement grants and profile XP sync (G0).
class GamificationService {
  GamificationService._();

  /// Verifier approve or in-app auto-unlock (server validates is_in_app).
  static Future<int?> grantVerifiedAchievement({
    required String userId,
    required String achievementId,
    String? reviewerNotes,
  }) async {
    if (!isSupabaseConfigured()) return null;
    try {
      final result = await getSupabase().rpc(
        'grant_verified_achievement',
        params: {
          'p_user_id': userId,
          'p_achievement_id': achievementId,
          'p_reviewer_notes': reviewerNotes,
        },
      );
      if (result is num) return result.toInt();
      return null;
    } catch (e, st) {
      debugPrint('grant_verified_achievement failed: $e\n$st');
      rethrow;
    }
  }

  /// Verifier reject with optional message to the resident.
  static Future<void> rejectAchievementSubmission({
    required String userId,
    required String achievementId,
    String? reviewerNotes,
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to reject achievements.');
    }
    await getSupabase().rpc(
      'reject_achievement_submission',
      params: {
        'p_user_id': userId,
        'p_achievement_id': achievementId,
        'p_reviewer_notes': reviewerNotes,
      },
    );
  }
}
