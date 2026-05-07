enum AchievementCategory {
  education,
  career,
  relationships,
  health,
  skills,
  travel,
  finance,
  community,
  funny,
  creative,
  profession,
  inApp,
}

enum AchievementStatus { locked, submitted, verified }

class Achievement {
  final String id;
  final AchievementCategory category;
  final String title;
  final String description;
  final int xpValue;
  final bool isFunny;
  final String icon;

  const Achievement({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.xpValue,
    this.isFunny = false,
    this.icon = 'star',
  });
}

class UserAchievement {
  final String achievementId;
  final AchievementStatus status;
  final String? proofUri;
  final int? submittedAt;
  final int? verifiedAt;
  /// AI confidence score from The Archivist (0.0–1.0).
  final double? aiConfidence;
  /// AI verifier notes.
  final String? aiNotes;

  const UserAchievement({
    required this.achievementId,
    this.status = AchievementStatus.submitted,
    this.proofUri,
    this.submittedAt,
    this.verifiedAt,
    this.aiConfidence,
    this.aiNotes,
  });

  UserAchievement copyWith({
    String? achievementId,
    AchievementStatus? status,
    String? proofUri,
    int? submittedAt,
    int? verifiedAt,
    double? aiConfidence,
    String? aiNotes,
  }) =>
      UserAchievement(
        achievementId: achievementId ?? this.achievementId,
        status: status ?? this.status,
        proofUri: proofUri ?? this.proofUri,
        submittedAt: submittedAt ?? this.submittedAt,
        verifiedAt: verifiedAt ?? this.verifiedAt,
        aiConfidence: aiConfidence ?? this.aiConfidence,
        aiNotes: aiNotes ?? this.aiNotes,
      );
}
