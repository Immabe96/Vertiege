import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../models/resident.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../shared/share_button.dart';
import '../../ui/buttons/v_button.dart';

/// A glassmorphism-style share card for a newly earned achievement.
///
/// Shows the achievement title, category, XP value, and a "Join me on
/// Vertiege" tagline in a square format suitable for social sharing.
class AchievementShareCard extends StatelessWidget {
  final Achievement achievement;
  final Resident resident;
  final int totalXp;

  const AchievementShareCard({
    super.key,
    required this.achievement,
    required this.resident,
    required this.totalXp,
  });

  Color get _categoryColor {
    switch (achievement.category) {
      case AchievementCategory.education:
        return VColors.achievementEducation;
      case AchievementCategory.career:
        return VColors.achievementCareer;
      case AchievementCategory.relationships:
        return VColors.achievementSocial;
      case AchievementCategory.health:
        return VColors.achievementHealth;
      case AchievementCategory.skills:
        return VColors.achievementKnowledge;
      case AchievementCategory.travel:
        return VColors.achievementAdventure;
      case AchievementCategory.finance:
        return VColors.achievementFinance;
      case AchievementCategory.community:
        return VColors.achievementSocial;
      case AchievementCategory.funny:
        return VColors.achievementCreative;
      case AchievementCategory.creative:
        return VColors.achievementCreative;
      case AchievementCategory.profession:
        return VColors.achievementCareer;
      case AchievementCategory.inApp:
        return VColors.primary;
    }
  }

  String get _categoryLabel {
    switch (achievement.category) {
      case AchievementCategory.education:
        return 'EDUCATION';
      case AchievementCategory.career:
        return 'CAREER';
      case AchievementCategory.relationships:
        return 'RELATIONSHIPS';
      case AchievementCategory.health:
        return 'HEALTH';
      case AchievementCategory.skills:
        return 'SKILLS';
      case AchievementCategory.travel:
        return 'TRAVEL';
      case AchievementCategory.finance:
        return 'FINANCE';
      case AchievementCategory.community:
        return 'COMMUNITY';
      case AchievementCategory.funny:
        return 'FUNNY';
      case AchievementCategory.creative:
        return 'CREATIVE';
      case AchievementCategory.profession:
        return 'PROFESSION';
      case AchievementCategory.inApp:
        return 'VERTIEGE';
    }
  }

  IconData get _categoryIcon {
    switch (achievement.category) {
      case AchievementCategory.education:
        return Icons.school;
      case AchievementCategory.career:
        return Icons.work;
      case AchievementCategory.relationships:
        return Icons.favorite;
      case AchievementCategory.health:
        return Icons.fitness_center;
      case AchievementCategory.skills:
        return Icons.build;
      case AchievementCategory.travel:
        return Icons.flight;
      case AchievementCategory.finance:
        return Icons.account_balance;
      case AchievementCategory.community:
        return Icons.groups;
      case AchievementCategory.funny:
        return Icons.mood;
      case AchievementCategory.creative:
        return Icons.palette;
      case AchievementCategory.profession:
        return Icons.badge;
      case AchievementCategory.inApp:
        return Icons.diamond;
    }
  }

  /// Shows the achievement share dialog.
  ///
  /// Call this when a new achievement is earned to present a "Share
  /// Achievement" option. The dialog renders this card wrapped in a
  /// [ShareButton] for one-tap capture and share.
  static Future<void> show(
    BuildContext context, {
    required Achievement achievement,
    required Resident resident,
    required int totalXp,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(VSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShareButton(
              shareText: 'I just earned ${achievement.title} on Vertiege!',
              onShared: () => Navigator.of(ctx).pop(),
              child: AchievementShareCard(
                achievement: achievement,
                resident: resident,
                totalXp: totalXp,
              ),
            ),
            const SizedBox(height: VSpacing.md),
            VButton(
              label: 'Close',
              onPressed: () => Navigator.of(ctx).pop(),
              variant: ButtonVariant.text,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 360,
      decoration: BoxDecoration(
        color: VColors.surface,
        borderRadius: BorderRadius.circular(VRadius.xxxl),
        border: Border.all(color: VColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: _categoryColor.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Category Header ───────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: VSpacing.xl,
              vertical: VSpacing.lg,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _categoryColor.withValues(alpha: 0.15),
                  _categoryColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: VSpacing.sm),
                // Category icon in circle
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _categoryColor.withValues(alpha: 0.15),
                    border: Border.all(
                      color: _categoryColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _categoryColor.withValues(alpha: 0.12),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _categoryIcon,
                    size: VIconSize.lg,
                    color: _categoryColor,
                  ),
                ),
                const SizedBox(height: VSpacing.md),
                // Category label
                Text(
                  _categoryLabel,
                  style: TextStyle(
                    fontSize: VFontSize.labelSm,
                    fontWeight: VFontWeight.bold,
                    color: _categoryColor.withValues(alpha: 0.8),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: VSpacing.sm),
                // Achievement title
                Text(
                  achievement.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: VFontSize.headlineMd,
                    fontWeight: VFontWeight.bold,
                    color: VColors.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: VSpacing.xs),
                // Description
                Text(
                  achievement.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: VFontSize.bodyMd,
                    color: VColors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // ── Spacer ─────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [VColors.surfaceBright, VColors.surface],
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.xl,
                vertical: VSpacing.lg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // XP badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.lg,
                      vertical: VSpacing.xs + 2,
                    ),
                    decoration: BoxDecoration(
                      color: VColors.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(VRadius.pill),
                      border: Border.all(
                        color: VColors.tertiary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: VIconSize.sm,
                          color: VColors.tertiary,
                        ),
                        const SizedBox(width: VSpacing.sm),
                        Text(
                          '+${achievement.xpValue} XP',
                          style: TextStyle(
                            fontSize: VFontSize.labelSm,
                            fontWeight: VFontWeight.bold,
                            color: VColors.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpacing.md),
                  // Earned by
                  Text(
                    'Earned by ${resident.name}',
                    style: TextStyle(
                      fontSize: VFontSize.bodyMd,
                      color: VColors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VSpacing.sm),
                  Text(
                    '${resident.tier.label}  •  $totalXp XP',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: VColors.outline,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: VSpacing.lg),
                  // Tagline
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpacing.lg,
                      vertical: VSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _categoryColor.withValues(alpha: 0.08),
                          _categoryColor.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        VRadius.md,
                      ),
                      border: Border.all(
                        color: _categoryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.diamond,
                          size: VIconSize.sm + 2,
                          color: _categoryColor.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: VSpacing.sm),
                        Text(
                          'Join me on Vertiege',
                          style: TextStyle(
                            fontSize: VFontSize.bodyMd,
                            fontWeight: VFontWeight.semiBold,
                            color: _categoryColor.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Category-colored bottom accent bar ─────────────
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _categoryColor.withValues(alpha: 0.9),
                  _categoryColor.withValues(alpha: 0.3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
