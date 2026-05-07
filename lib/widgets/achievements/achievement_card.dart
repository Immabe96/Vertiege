import 'package:flutter/material.dart';
import '../../models/achievement.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../core/fade_in.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final AchievementStatus status;
  final VoidCallback? onPress;
  final int index;
  /// AI confidence score from The Archivist (0.0–1.0).
  final double? aiConfidence;
  /// AI verifier notes.
  final String? aiNotes;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.status,
    this.onPress,
    this.index = 0,
    this.aiConfidence,
    this.aiNotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isVerified = status == AchievementStatus.verified;
    final isSubmitted = status == AchievementStatus.submitted;
    final isLocked = status == AchievementStatus.locked;

    final gradientColors = isVerified
        ? AppColors.gradientPrimary
        : isSubmitted
            ? AppColors.gradientWarm
            : AppColors.gradientDark;

    final borderDecoration = isVerified
        ? BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.semanticSuccess, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.semanticSuccess.withValues(alpha: 0.45),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          )
        : isSubmitted
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentStreak,
                  width: 2.5,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              )
            : null;

    final progressFraction = switch (status) {
      AchievementStatus.verified => 1.0,
      AchievementStatus.submitted => 0.7,
      AchievementStatus.locked => 0.0,
    };

    return FadeIn(
      delayMs: index * 70,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Card(
          color: AppColors.glassBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
            side: isVerified
                ? BorderSide(color: AppColors.semanticSuccess.withValues(alpha: 0.4), width: 1.5)
                : isSubmitted
                    ? BorderSide(color: AppColors.accentStreak.withValues(alpha: 0.3), width: 1)
                    : BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
          child: InkWell(
            onTap: status != AchievementStatus.verified ? onPress : null,
            borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress ring + icon container
                  _AchievementIcon(
                    progress: progressFraction,
                    gradientColors: gradientColors,
                    borderDecoration: borderDecoration,
                    status: status,
                    iconName: achievement.icon,
                  ),
                  const SizedBox(height: Spacing.sm + 4),
                  // Title
                  Text(
                    achievement.title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeights.bold,
                      height: LineHeight.button,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.xs),
                  // Description
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      fontSize: FontSizes.caption,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: Spacing.sm),
                  // XP badge + status indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _XpBadge(xp: achievement.xpValue),
                      if (isSubmitted) ...[
                        const SizedBox(width: Spacing.xs),
                        _StatusChip(
                          label: 'Pending Review',
                          color: AppColors.accentStreak,
                          icon: Icons.schedule,
                        ),
                      ],
                      if (isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: Spacing.xs),
                          child: Icon(
                            Icons.check_circle,
                            size: IconSizes.sm,
                            color: AppColors.semanticSuccess,
                          ),
                        ),
                    ],
                  ),
                  // AI confidence indicator (The Archivist)
                  if (aiConfidence != null && isSubmitted)
                    _AiConfidenceChip(
                      confidence: aiConfidence!,
                      aiNotes: aiNotes,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Achievement Icon with gradient, ring, and status overlay ───────

class _AchievementIcon extends StatelessWidget {
  final double progress;
  final List<Color> gradientColors;
  final BoxDecoration? borderDecoration;
  final AchievementStatus status;
  final String iconName;

  const _AchievementIcon({
    required this.progress,
    required this.gradientColors,
    required this.borderDecoration,
    required this.status,
    required this.iconName,
  });

  IconData _resolveIcon() {
    return switch (iconName) {
      'school' => Icons.school,
      'translate' => Icons.translate,
      'verified' => Icons.verified,
      'work' => Icons.work,
      'trending_up' => Icons.trending_up,
      'swap_horiz' => Icons.swap_horiz,
      'store' => Icons.store,
      'corporate_fare' => Icons.corporate_fare,
      'payments' => Icons.payments,
      'home_work' => Icons.home_work,
      'beach_access' => Icons.beach_access,
      'favorite' => Icons.favorite,
      'ring_volume' => Icons.ring_volume,
      'home' => Icons.home,
      'child_care' => Icons.child_care,
      'people' => Icons.people,
      'directions_run' => Icons.directions_run,
      'monitor_weight' => Icons.monitor_weight,
      'fitness_center' => Icons.fitness_center,
      'pool' => Icons.pool,
      'directions_bike' => Icons.directions_bike,
      'block' => Icons.block,
      'self_improvement' => Icons.self_improvement,
      'code' => Icons.code,
      'music_note' => Icons.music_note,
      'restaurant' => Icons.restaurant,
      'directions_car' => Icons.directions_car,
      'surfing' => Icons.surfing,
      'mic' => Icons.mic,
      'construction' => Icons.construction,
      'flight' => Icons.flight,
      'flight_takeoff' => Icons.flight_takeoff,
      'public' => Icons.public,
      'language' => Icons.language,
      'star' => Icons.star,
      'savings' => Icons.savings,
      'check_circle' => Icons.check_circle,
      'shield' => Icons.shield,
      'volunteer_activism' => Icons.volunteer_activism,
      'bloodtype' => Icons.bloodtype,
      'diversity_3' => Icons.diversity_3,
      'forest' => Icons.forest,
      'event' => Icons.event,
      'nightlight' => Icons.nightlight,
      'groups' => Icons.groups,
      'local_pizza' => Icons.local_pizza,
      'toys' => Icons.toys,
      'pets' => Icons.pets,
      'phone_in_talk' => Icons.phone_in_talk,
      'tv' => Icons.tv,
      'question_mark' => Icons.question_mark,
      'chair' => Icons.chair,
      'menu_book' => Icons.menu_book,
      'palette' => Icons.palette,
      'lyrics' => Icons.lyrics,
      'play_circle' => Icons.play_circle,
      'theater_comedy' => Icons.theater_comedy,
      'local_hospital' => Icons.local_hospital,
      'engineering' => Icons.engineering,
      'gavel' => Icons.gavel,
      'account_balance' => Icons.account_balance,
      'brush' => Icons.brush,
      _ => Icons.emoji_events,
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = IconSizes.xl;
    final ringStrokeWidth = 3.5;

    return SizedBox(
      width: size + 16,
      height: size + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring (shown for non-verified states)
          if (progress < 1.0)
            SizedBox(
              width: size + 12,
              height: size + 12,
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: ringStrokeWidth,
                strokeCap: StrokeCap.round,
                color: progress == 0.0
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.accentStreak,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          // Gradient icon circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: borderDecoration?.border as Border?,
              boxShadow: borderDecoration?.boxShadow,
            ),
            child: Center(
              child: Icon(_resolveIcon(), size: 24, color: Colors.white),
            ),
          ),
          // Status overlay badges
          if (status == AchievementStatus.verified)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.semanticSuccess,
                ),
                child: const Icon(Icons.check, size: 14, color: Colors.white),
              ),
            ),
          if (status == AchievementStatus.submitted)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentStreak,
                ),
                child: const Icon(Icons.access_time, size: 14, color: Colors.white),
              ),
            ),
          if (status == AchievementStatus.locked)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade700,
                ),
                child: const Icon(Icons.lock, size: 13, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── XP Badge ───────────────────────────────────────────────────────

class _XpBadge extends StatelessWidget {
  final int xp;

  const _XpBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
      ),
      child: Text(
        '+$xp XP',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: FontSizes.caption,
          fontWeight: FontWeights.bold,
        ),
      ),
    );
  }
}

// ─── Status Chip ────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs + 2, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(RadiusTokens.pill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSizes.xs, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeights.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Confidence Chip (The Archivist) ─────────────────────────────

class _AiConfidenceChip extends StatelessWidget {
  final double confidence;
  final String? aiNotes;

  const _AiConfidenceChip({
    required this.confidence,
    this.aiNotes,
  });

  @override
  Widget build(BuildContext context) {
    final isHigh = confidence >= 0.75;
    final isMedium = confidence >= 0.4 && confidence < 0.75;

    final Color color;
    final IconData icon;
    final String label;

    if (isHigh) {
      color = AppColors.semanticSuccess;
      icon = Icons.check_circle;
      label = 'AI-Verified';
    } else if (isMedium) {
      color = AppColors.accentStreak;
      icon = Icons.access_time;
      label = 'Under Review';
    } else {
      color = Colors.orange;
      icon = Icons.help_outline;
      label = 'Requires Manual Verification';
    }

    return Padding(
      padding: const EdgeInsets.only(top: Spacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.xs + 2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(RadiusTokens.pill),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: IconSizes.xs, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeights.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(confidence * 100).toInt()}%',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (aiNotes != null && aiNotes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                aiNotes!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                      fontSize: 9,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
