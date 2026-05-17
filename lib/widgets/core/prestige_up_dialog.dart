import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';

class PrestigeUpDialog extends StatefulWidget {
  final int prestigeLevel;
  final int newPrestigeStars;

  const PrestigeUpDialog({
    super.key,
    required this.prestigeLevel,
    required this.newPrestigeStars,
  });

  static Future<void> show(
    BuildContext context, {
    required int prestigeLevel,
    required int newPrestigeStars,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrestigeUpDialog(
        prestigeLevel: prestigeLevel,
        newPrestigeStars: newPrestigeStars,
      ),
    );
  }

  @override
  State<PrestigeUpDialog> createState() => _PrestigeUpDialogState();
}

class _PrestigeUpDialogState extends State<PrestigeUpDialog> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String _prestigeTitle(int stars) {
    if (stars == 1) return 'Apex I';
    return 'Apex $stars';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        Dialog(
          backgroundColor: isDark
              ? VColors.surfaceContainerDark
              : VColors.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(RadiusTokens.xl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(Spacing.sm),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [VColors.tertiary, VColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: VColors.onTertiary,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Text(
                  'ASCENSION COMPLETE',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeights.bold,
                    color: VColors.tertiary,
                    letterSpacing: LetterSpacing.label,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.lg,
                    vertical: Spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: VColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    border: Border.all(
                      color: VColors.tertiary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...List.generate(
                        widget.newPrestigeStars,
                        (i) => Padding(
                          padding: EdgeInsets.only(
                            right: i < widget.newPrestigeStars - 1 ? 4 : 0,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: VColors.tertiary,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  _prestigeTitle(widget.newPrestigeStars),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeights.bold,
                    color: VColors.tertiary,
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                Container(
                  padding: const EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    color: isDark
                        ? VColors.surfaceDark
                        : VColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                    border: Border.all(
                      color: VColors.tertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prestige Rewards:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeights.bold,
                          color: VColors.tertiary,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      _PrestigePerkRow(
                        icon: Icons.badge,
                        text: 'Exclusive prestige frame unlocked',
                      ),
                      _PrestigePerkRow(
                        icon: Icons.star,
                        text: 'Prestige star ${widget.newPrestigeStars} earned',
                      ),
                      _PrestigePerkRow(
                        icon: Icons.refresh,
                        text: 'XP reset — climb the tiers again!',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: VColors.tertiary,
                      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                    ),
                    child: const Text('Continue'),
                  ),
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
              VColors.tertiary,
              VColors.secondary,
              VColors.tierApex,
              VColors.tierOldMoney,
            ],
          ),
        ),
      ],
    );
  }
}

class _PrestigePerkRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PrestigePerkRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: VColors.tertiary),
          const SizedBox(width: Spacing.xs),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
