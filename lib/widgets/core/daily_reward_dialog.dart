import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/daily_reward_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

/// A celebratory glass-modal dialog shown once per day when the resident
/// collects their daily resonance reward.
///
/// Features an animated icon reveal and a "COLLECT" button.
class DailyRewardDialog extends StatefulWidget {
  final DailyReward reward;
  final VoidCallback onCollect;

  const DailyRewardDialog({
    super.key,
    required this.reward,
    required this.onCollect,
  });

  /// Show the dialog over the given context.
  static Future<void> show(
    BuildContext context, {
    required DailyReward reward,
    required VoidCallback onCollect,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Daily Reward',
      barrierColor: VColors.surface.withValues(alpha: 0.85),
      transitionDuration: AnimDurations.normal,
      pageBuilder: (context, animation, secondaryAnimation) {
        return DailyRewardDialog(reward: reward, onCollect: onCollect);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: AnimCurves.bouncy),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  bool _collected = false;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _iconScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 60),
          TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
        );

    // Start the icon animation after a brief delay
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _iconController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _onCollect() {
    if (_collected) return;
    setState(() => _collected = true);
    widget.onCollect();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: Spacing.xl),
        padding: const EdgeInsets.all(Spacing.xl),
        decoration: BoxDecoration(
          color: VColors.glassBackground,
          borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
          border: Border.all(color: VColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: VColors.tertiary.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'DAILY RESONANCE',
              style: GoogleFonts.manrope(
                fontSize: FontSizes.headlineMd,
                fontWeight: FontWeights.bold,
                color: VColors.tertiary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: Spacing.xl),

            // Animated reward icon
            ScaleTransition(
              scale: _iconScale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.reward.color.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.reward.color.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  widget.reward.icon,
                  size: 40,
                  color: widget.reward.color,
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),

            // Reward text
            Text(
              widget.reward.label,
              style: GoogleFonts.manrope(
                fontSize: FontSizes.displayXl,
                fontWeight: FontWeights.bold,
                color: widget.reward.isShield
                    ? VColors.tierHustler
                    : VColors.onSurface,
              ),
            ),
            const SizedBox(height: Spacing.sm),

            Text(
              widget.reward.isShield
                  ? 'Protects your streak for one missed day!'
                  : 'Resonance energy granted',
              style: theme.textTheme.bodySmall?.copyWith(
                color: VColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),

            // Collect button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _collected ? null : _onCollect,
                style: FilledButton.styleFrom(
                  backgroundColor: VColors.tertiary,
                  foregroundColor: VColors.onTertiary,
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(RadiusTokens.card),
                  ),
                ),
                child: Text(
                  _collected ? 'COLLECTED!' : 'COLLECT',
                  style: GoogleFonts.manrope(
                    fontSize: FontSizes.bodyLg,
                    fontWeight: FontWeights.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
