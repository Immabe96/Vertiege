import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';

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
    return showFDialog(
      context: context,
      barrierDismissible: false,
      builder: (context, style, animation) => PrestigeUpDialog(
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        FDialog.raw(
          builder: (context, dialogStyle) => Padding(
            padding: const EdgeInsets.all(VSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(VSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [VColors.tertiary, VColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 48,
                    color: VColors.onTertiary,
                  ),
                ),
                const SizedBox(height: VSpacing.lg),
                Text(
                  'ASCENSION COMPLETE',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: VFontWeight.bold,
                    color: VColors.tertiary,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: VSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.lg,
                    vertical: VSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: VColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(VRadius.pill),
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
                            size: VIconSize.lg,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VSpacing.sm),
                Text(
                  _prestigeTitle(widget.newPrestigeStars),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: VFontWeight.bold,
                    color: VColors.tertiary,
                  ),
                ),
                const SizedBox(height: VSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(VSpacing.md),
                  decoration: BoxDecoration(
                    color: VColors.surfaceDark,
                    borderRadius: BorderRadius.circular(VRadius.md),
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
                          fontWeight: VFontWeight.bold,
                          color: VColors.tertiary,
                        ),
                      ),
                      const SizedBox(height: VSpacing.xs),
                      const _PrestigePerkRow(
                        icon: Icons.badge,
                        text: 'Exclusive prestige frame unlocked',
                      ),
                      _PrestigePerkRow(
                        icon: Icons.star,
                        text: 'Prestige star ${widget.newPrestigeStars} earned',
                      ),
                      const _PrestigePerkRow(
                        icon: Icons.refresh,
                        text: 'XP reset — climb the tiers again!',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: VIconSize.sm, color: VColors.tertiary),
          const SizedBox(width: VSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: VColors.onSurfaceDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
