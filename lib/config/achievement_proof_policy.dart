import '../models/achievement.dart';

/// Default verifier submission rules per category (manual review).
class AchievementProofSpec {
  final AchievementProofType proofType;
  final int minProofImages;
  final int maxProofImages;
  final String proofHint;

  const AchievementProofSpec({
    required this.proofType,
    this.minProofImages = 1,
    this.maxProofImages = 1,
    required this.proofHint,
  });
}

/// Per-id overrides for achievements with bespoke proof (explicit in catalog source).
const achievementProofOverrides = <String, AchievementProofSpec>{
  'life-midnight-snack': AchievementProofSpec(
    proofType: AchievementProofType.optional,
    proofHint: 'Fridge, snack, or receipt — bonus points for chaos.',
  ),
  'life-plant-parent': AchievementProofSpec(
    proofType: AchievementProofType.multi,
    minProofImages: 2,
    maxProofImages: 4,
    proofHint: 'Show the plant now and when you got it (two photos).',
  ),
  'life-roadtrip': AchievementProofSpec(
    proofType: AchievementProofType.location,
    minProofImages: 2,
    maxProofImages: 5,
    proofHint: 'Include a landmark or welcome sign plus you on the road.',
  ),
  'life-confession': AchievementProofSpec(
    proofType: AchievementProofType.required,
    proofHint: 'Screenshot, journal page, or photo that backs the story.',
  ),
  'life-chaos-king': AchievementProofSpec(
    proofType: AchievementProofType.optional,
    proofHint: 'The messier the evidence, the better.',
  ),
  'life-secret-talent': AchievementProofSpec(
    proofType: AchievementProofType.multi,
    minProofImages: 1,
    maxProofImages: 3,
    proofHint: 'Photo or short clip still — show the talent in action.',
  ),
  'life-survived-monday': AchievementProofSpec(
    proofType: AchievementProofType.optional,
    proofHint: 'Coffee, calendar, or desk chaos — optional but fun.',
  ),
  'life-found-love': AchievementProofSpec(
    proofType: AchievementProofType.multi,
    minProofImages: 2,
    maxProofImages: 4,
    proofHint: 'Couple photo plus one detail (ring, trip, message redacted).',
  ),
  'life-dark-humor': AchievementProofSpec(
    proofType: AchievementProofType.optional,
    proofHint: 'Chat screenshot with names blurred is fine.',
  ),
  'life-main-character': AchievementProofSpec(
    proofType: AchievementProofType.location,
    minProofImages: 1,
    maxProofImages: 3,
    proofHint: 'Show the scene — skyline, rain, stage, or crowd.',
  ),
};

AchievementProofSpec proofSpecForCategory(
  AchievementCategory category, {
  bool isFunny = false,
}) {
  if (isFunny || category == AchievementCategory.funny) {
    return const AchievementProofSpec(
      proofType: AchievementProofType.optional,
      maxProofImages: 3,
      proofHint:
          'Funny proof is optional — meme, screenshot, or photo that tells the story.',
    );
  }
  return switch (category) {
    AchievementCategory.education => const AchievementProofSpec(
      proofType: AchievementProofType.required,
      proofHint:
          'Diploma, transcript, certificate, or official letter with personal details redacted.',
    ),
    AchievementCategory.career => const AchievementProofSpec(
      proofType: AchievementProofType.required,
      proofHint:
          'Offer letter, pay stub, badge, or workplace photo with identifying info blurred.',
    ),
    AchievementCategory.profession => const AchievementProofSpec(
      proofType: AchievementProofType.required,
      proofHint:
          'License, credential, ID badge, or official verification of your profession.',
    ),
    AchievementCategory.relationships => const AchievementProofSpec(
      proofType: AchievementProofType.multi,
      minProofImages: 2,
      maxProofImages: 4,
      proofHint:
          'Two photos or documents that show the milestone (blur faces if needed).',
    ),
    AchievementCategory.health => const AchievementProofSpec(
      proofType: AchievementProofType.multi,
      minProofImages: 1,
      maxProofImages: 3,
      proofHint:
          'App screenshot, race result, scale trend, or gym log — no sensitive medical IDs.',
    ),
    AchievementCategory.skills => const AchievementProofSpec(
      proofType: AchievementProofType.required,
      proofHint:
          'Show the skill in action: project screenshot, performance clip still, or certificate.',
    ),
    AchievementCategory.travel => const AchievementProofSpec(
      proofType: AchievementProofType.location,
      minProofImages: 2,
      maxProofImages: 5,
      proofHint:
          'Landmark, boarding pass, or you at the destination (two angles help).',
    ),
    AchievementCategory.finance => const AchievementProofSpec(
      proofType: AchievementProofType.required,
      proofHint:
          'Bank letter, payoff screenshot, or statement with account numbers hidden.',
    ),
    AchievementCategory.community => const AchievementProofSpec(
      proofType: AchievementProofType.required,
      proofHint:
          'Volunteer confirmation, event photo, or org letter showing your contribution.',
    ),
    AchievementCategory.creative => const AchievementProofSpec(
      proofType: AchievementProofType.multi,
      minProofImages: 1,
      maxProofImages: 4,
      proofHint:
          'Portfolio piece, storefront link screenshot, or performance photo.',
    ),
    AchievementCategory.life => const AchievementProofSpec(
      proofType: AchievementProofType.multi,
      minProofImages: 1,
      maxProofImages: 4,
      proofHint:
          'Photos that show the moment — blur faces or addresses if needed.',
    ),
    AchievementCategory.funny => const AchievementProofSpec(
      proofType: AchievementProofType.optional,
      maxProofImages: 3,
      proofHint:
          'Funny proof is optional — meme, screenshot, or photo that tells the story.',
    ),
    AchievementCategory.inApp => const AchievementProofSpec(
      proofType: AchievementProofType.optional,
      proofHint: 'Unlocked automatically in Vertiege — no proof required.',
    ),
  };
}

bool _hasExplicitProofInSource(Achievement a) {
  if (a.proofHint != null && a.proofHint!.trim().isNotEmpty) return true;
  if (a.proofType != AchievementProofType.optional) return true;
  if (a.minProofImages > 0 || a.maxProofImages > 1) return true;
  return achievementProofOverrides.containsKey(a.id);
}

Achievement _applyProofPolicy(Achievement a) {
  if (a.category == AchievementCategory.inApp) {
    return a.copyWith(
      proofType: AchievementProofType.optional,
      minProofImages: 0,
      maxProofImages: 1,
      proofHint: 'Unlocked automatically in Vertiege — no proof required.',
    );
  }
  if (_hasExplicitProofInSource(a)) {
    final override = achievementProofOverrides[a.id];
    if (override != null) {
      return a.copyWith(
        proofType: override.proofType,
        minProofImages: override.minProofImages,
        maxProofImages: override.maxProofImages,
        proofHint: override.proofHint,
      );
    }
    return a;
  }
  final spec = achievementProofOverrides[a.id] ??
      proofSpecForCategory(a.category, isFunny: a.isFunny);
  return a.copyWith(
    proofType: spec.proofType,
    minProofImages: spec.minProofImages,
    maxProofImages: spec.maxProofImages,
    proofHint: spec.proofHint,
  );
}

/// Merges raw catalog entries and applies verifier submission requirements.
List<Achievement> resolveAchievementCatalog(List<Achievement> raw) {
  return raw.map(_applyProofPolicy).toList(growable: false);
}
