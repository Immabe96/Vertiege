import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';

class TierUpDialog extends StatefulWidget {
  final int oldTier;
  final int newTier;
  final List<String> perks;

  const TierUpDialog({
    super.key,
    required this.oldTier,
    required this.newTier,
    required this.perks,
  });

  static Future<void> show(
    BuildContext context, {
    required int oldTier,
    required int newTier,
    required List<String> perks,
  }) {
    return showFDialog(
      context: context,
      barrierDismissible: false,
      builder: (context, style, animation) => TierUpDialog(
        oldTier: oldTier,
        newTier: newTier,
        perks: perks,
      ),
    );
  }

  @override
  State<TierUpDialog> createState() => _TierUpDialogState();
}

class _TierUpDialogState extends State<TierUpDialog> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _tierName(int tier) {
    switch (tier) {
      case 5:
        return 'Apex';
      case 4:
        return 'Old Money';
      case 3:
        return 'Elite';
      case 2:
        return 'High Roller';
      default:
        return 'Hustler';
    }
  }

  Color _tierColor(int tier) {
    switch (tier) {
      case 5:
        return VColors.tierApex;
      case 4:
        return VColors.tierOldMoney;
      case 3:
        return VColors.tierElite;
      case 2:
        return VColors.tierHighRoller;
      default:
        return VColors.tierHustler;
    }
  }

  IconData _tierIcon(int tier) {
    switch (tier) {
      case 5:
        return Icons.diamond;
      case 4:
        return Icons.rocket_launch;
      case 3:
        return Icons.star;
      case 2:
        return Icons.star_border;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FDialog.raw(
          builder: (context, dialogStyle) => Padding(
            padding: const EdgeInsets.all(VSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TIER UP!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: VFontWeight.bold,
                    color: VColors.tertiary,
                  ),
                ),
                const SizedBox(height: VSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _TierBadgeDisplay(
                      tier: widget.oldTier,
                      label: _tierName(widget.oldTier),
                      color: _tierColor(widget.oldTier),
                      icon: _tierIcon(widget.oldTier),
                      opacity: 0.5,
                    ),
                    const SizedBox(width: VSpacing.md),
                    Icon(
                      Icons.arrow_forward,
                      size: 32,
                      color: VColors.success,
                    ),
                    const SizedBox(width: VSpacing.md),
                    _TierBadgeDisplay(
                      tier: widget.newTier,
                      label: _tierName(widget.newTier),
                      color: _tierColor(widget.newTier),
                      icon: _tierIcon(widget.newTier),
                      glow: true,
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(VSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? VColors.surfaceDark
                        : VColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(VRadius.md),
                    border: Border.all(
                      color: _tierColor(widget.newTier).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You unlocked:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: VFontWeight.bold,
                          color: VColors.primary,
                        ),
                      ),
                      const SizedBox(height: VSpacing.xs),
                      ...widget.perks.map(
                        (perk) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: VColors.success,
                              ),
                              const SizedBox(width: VSpacing.xs),
                              Expanded(
                                child: Text(
                                  perk,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? VColors.onSurfaceDark
                                        : VColors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VSpacing.lg),
                VButton(
                  label: 'Continue',
                  onPressed: () => Navigator.of(context).pop(),
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              VColors.primary,
              VColors.tertiary,
              VColors.secondary,
              VColors.tierOldMoney,
              VColors.tierApex,
            ],
          ),
        ),
      ],
    );
  }
}

class _TierBadgeDisplay extends StatelessWidget {
  final int tier;
  final String label;
  final Color color;
  final IconData icon;
  final bool glow;
  final double opacity;

  const _TierBadgeDisplay({
    required this.tier,
    required this.label,
    required this.color,
    required this.icon,
    this.glow = false,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(VSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(VRadius.lg),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: VSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: VFontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
