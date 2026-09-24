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
  life,
  profession,
  inApp,
}

/// How residents should submit proof for an achievement.
enum AchievementProofType {
  /// Proof optional (text-only submit allowed).
  optional,

  /// At least one image required.
  required,

  /// Multiple images (see min/max on [Achievement]).
  multi,

  /// Emphasizes place/object in frame (still image-based).
  location,
}

enum AchievementStatus { locked, submitted, verified, rejected }

class Achievement {
  final String id;
  final AchievementCategory category;
  final String title;
  final String description;
  final int xpValue;
  final bool isFunny;
  final String icon;
  final AchievementProofType proofType;
  final int minProofImages;
  final int maxProofImages;
  final String? proofHint;

  const Achievement({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.xpValue,
    this.isFunny = false,
    this.icon = 'star',
    this.proofType = AchievementProofType.optional,
    this.minProofImages = 0,
    this.maxProofImages = 1,
    this.proofHint,
  });

  int get effectiveMinImages => switch (proofType) {
    AchievementProofType.optional => 0,
    AchievementProofType.required => 1,
    AchievementProofType.location => 1,
    AchievementProofType.multi => minProofImages < 1 ? 1 : minProofImages,
  };

  int get effectiveMaxImages => switch (proofType) {
    AchievementProofType.multi => maxProofImages < 2 ? 4 : maxProofImages,
    _ => 1,
  };

  bool get proofRequired => effectiveMinImages > 0;

  Achievement copyWith({
    String? id,
    AchievementCategory? category,
    String? title,
    String? description,
    int? xpValue,
    bool? isFunny,
    String? icon,
    AchievementProofType? proofType,
    int? minProofImages,
    int? maxProofImages,
    String? proofHint,
  }) =>
      Achievement(
        id: id ?? this.id,
        category: category ?? this.category,
        title: title ?? this.title,
        description: description ?? this.description,
        xpValue: xpValue ?? this.xpValue,
        isFunny: isFunny ?? this.isFunny,
        icon: icon ?? this.icon,
        proofType: proofType ?? this.proofType,
        minProofImages: minProofImages ?? this.minProofImages,
        maxProofImages: maxProofImages ?? this.maxProofImages,
        proofHint: proofHint ?? this.proofHint,
      );
}

class UserAchievement {
  final String achievementId;
  final AchievementStatus status;
  final List<String> proofUris;
  final int? submittedAt;
  final int? verifiedAt;

  /// Optional reviewer confidence (legacy column; unused for manual-only review).
  final double? aiConfidence;

  /// Reviewer notes from staff (e.g. rejection reason).
  final String? aiNotes;
  final bool isProfileVisible;
  final int? featuredOrder;

  const UserAchievement({
    required this.achievementId,
    this.status = AchievementStatus.submitted,
    this.proofUris = const [],
    this.submittedAt,
    this.verifiedAt,
    this.aiConfidence,
    this.aiNotes,
    this.isProfileVisible = true,
    this.featuredOrder,
  });

  /// First proof URL (legacy / compact display).
  String? get proofUri => proofUris.isNotEmpty ? proofUris.first : null;

  UserAchievement copyWith({
    String? achievementId,
    AchievementStatus? status,
    List<String>? proofUris,
    int? submittedAt,
    int? verifiedAt,
    double? aiConfidence,
    String? aiNotes,
    bool? isProfileVisible,
    int? featuredOrder,
    bool clearFeaturedOrder = false,
  }) => UserAchievement(
    achievementId: achievementId ?? this.achievementId,
    status: status ?? this.status,
    proofUris: proofUris ?? this.proofUris,
    submittedAt: submittedAt ?? this.submittedAt,
    verifiedAt: verifiedAt ?? this.verifiedAt,
    aiConfidence: aiConfidence ?? this.aiConfidence,
    aiNotes: aiNotes ?? this.aiNotes,
    isProfileVisible: isProfileVisible ?? this.isProfileVisible,
    featuredOrder: clearFeaturedOrder ? null : (featuredOrder ?? this.featuredOrder),
  );
}
