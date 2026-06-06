import 'package:flutter/material.dart';
import '../../services/daily_reward_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

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
      transitionDuration: VAnimation.normal,
      pageBuilder: (context, animation, secondaryAnimation) {
        return DailyRewardDialog(reward: reward, onCollect: onCollect);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut),
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
    // TweenSequence requires t in [0, 1]; elastic curves can overshoot — keep parent linear.
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.5), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 40),
    ]).animate(_iconController);

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
    Navigator.of(context).pop();
  }

  void _dismissWithoutCollecting() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      child: Center(
        child: Container(
        margin: const EdgeInsets.symmetric(horizontal: VSpacing.xl),
        padding: const EdgeInsets.all(VSpacing.xl),
        decoration: BoxDecoration(
          color: VColors.glassBackground,
          borderRadius: BorderRadius.circular(VRadius.md),
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
              style: TextStyle(
                fontSize: VFontSize.headlineMd,
                fontWeight: VFontWeight.bold,
                color: VColors.tertiary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: VSpacing.xl),

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
            const SizedBox(height: VSpacing.lg),

            // Reward text
            Text(
              widget.reward.label,
              style: TextStyle(
                fontSize: VFontSize.displayXl,
                fontWeight: VFontWeight.bold,
                color: widget.reward.isShield
                    ? VColors.tierHustler
                    : VColors.onSurface,
              ),
            ),
            const SizedBox(height: VSpacing.sm),

            Text(
              widget.reward.isShield
                  ? 'Protects your streak for one missed day!'
                  : 'Resonance energy granted',
              style: theme.textTheme.bodySmall?.copyWith(
                color: VColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.xl),

            // Collect button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onCollect,
                style: FilledButton.styleFrom(
                  backgroundColor: VColors.tertiary,
                  foregroundColor: VColors.onTertiary,
                  padding: const EdgeInsets.symmetric(vertical: VSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VRadius.lg),
                  ),
                ),
                child: Text(
                  'COLLECT',
                  style: TextStyle(
                    fontSize: VFontSize.bodyLg,
                    fontWeight: VFontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: VSpacing.sm),
            TextButton(
              onPressed: _dismissWithoutCollecting,
              child: Text(
                'Not now',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: VColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
