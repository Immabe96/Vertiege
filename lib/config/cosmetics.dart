import 'package:flutter/material.dart';
import '../theme/v_colors.dart';

class CosmeticFrame {
  final String name;
  final Color color;
  final double shadowRadius;
  final double shadowOpacity;
  final double elevation;

  const CosmeticFrame({
    required this.name,
    required this.color,
    this.shadowRadius = 4,
    this.shadowOpacity = 0.3,
    this.elevation = 2,
  });
}

const Map<String, CosmeticFrame> cosmeticFrames = {
  'none': CosmeticFrame(name: 'None', color: Colors.transparent),
  'bronze': CosmeticFrame(
    name: 'Bronze',
    color: VColors.primary,
    shadowRadius: 6,
    shadowOpacity: 0.4,
    elevation: 3,
  ),
  'silver': CosmeticFrame(
    name: 'Silver',
    color: VColors.secondary,
    shadowRadius: 8,
    shadowOpacity: 0.5,
    elevation: 4,
  ),
  'gold': CosmeticFrame(
    name: 'Gold',
    color: VColors.tertiary,
    shadowRadius: 10,
    shadowOpacity: 0.6,
    elevation: 5,
  ),
  'diamond': CosmeticFrame(
    name: 'Diamond',
    color: VColors.tierElite,
    shadowRadius: 12,
    shadowOpacity: 0.7,
    elevation: 6,
  ),
};

CosmeticFrame getFrameForXp(int totalXp) {
  if (totalXp >= 50000) return cosmeticFrames['diamond']!;
  if (totalXp >= 10000) return cosmeticFrames['gold']!;
  if (totalXp >= 2000) return cosmeticFrames['silver']!;
  if (totalXp >= 500) return cosmeticFrames['bronze']!;
  return cosmeticFrames['none']!;
}

class ProfessionCosmetic {
  final String profession;
  final Color color;
  final String iconAsset;

  const ProfessionCosmetic({
    required this.profession,
    required this.color,
    required this.iconAsset,
  });
}

const Map<String, ProfessionCosmetic> professionCosmetics = {
  'Medical': ProfessionCosmetic(
    profession: 'Medical',
    color: Color(0xFF2D8B57),
    iconAsset: 'assets/generated/prof-doctor.png',
  ),
  'Engineering': ProfessionCosmetic(
    profession: 'Engineering',
    color: Color(0xFF1565C0),
    iconAsset: 'assets/generated/prof-engineer.png',
  ),
  'Finance': ProfessionCosmetic(
    profession: 'Finance',
    color: Color(0xFFD4A843),
    iconAsset: 'assets/generated/prof-finance.png',
  ),
  'Legal': ProfessionCosmetic(
    profession: 'Legal',
    color: Color(0xFF8B2252),
    iconAsset: 'assets/generated/prof-attorney.png',
  ),
  'Arts': ProfessionCosmetic(
    profession: 'Arts',
    color: Color(0xFF7B1FA2),
    iconAsset: 'assets/generated/prof-artist.png',
  ),
  'Aviation': ProfessionCosmetic(
    profession: 'Aviation',
    color: Color(0xFF0277BD),
    iconAsset: 'assets/generated/prof-pilot.png',
  ),
};

const Map<String, String> decorationLabels = {
  'Medical_badge': 'Verified Doctor',
  'Engineering_badge': 'Verified Engineer',
  'Legal_badge': 'Verified Attorney',
  'Finance_badge': 'Verified Financier',
  'Arts_badge': 'Verified Artist',
  'Aviation_badge': 'Verified Pilot',
  'Technology_badge': 'Verified Technologist',
};

/// Profession badges earned via verification (not shop cosmetics).
List<String> professionBadgeIdsFor(Iterable<String> verifiedRoles) {
  return verifiedRoles
      .map((role) => '${role}_badge')
      .where(decorationLabels.containsKey)
      .toSet()
      .toList();
}

enum DecorationType {
  circle,
  hexagon,
  target,
  ripple,
  crosshair,
  hexagonRipple,
  progressBar,
  concentricCircles,
}

DecorationType decorationTypeForBadge(String badgeId) {
  return switch (badgeId) {
    'Medical_badge' => DecorationType.circle,
    'Engineering_badge' => DecorationType.hexagon,
    'Legal_badge' => DecorationType.target,
    'Finance_badge' => DecorationType.ripple,
    'Arts_badge' => DecorationType.crosshair,
    'Aviation_badge' => DecorationType.hexagonRipple,
    'Technology_badge' => DecorationType.progressBar,
    _ => DecorationType.target,
  };
}
