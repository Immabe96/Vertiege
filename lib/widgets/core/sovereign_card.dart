import 'package:flutter/material.dart';
import 'glow_border.dart';
import 'glass_panel.dart';
import '../../theme/v_tokens.dart';

enum CardTier { apex, elite, hustler }

class SovereignCard extends StatelessWidget {
  final Widget child;
  final CardTier tier;
  final VoidCallback? onTap;
  final bool glass;
  final bool useBlur;

  const SovereignCard({
    super.key,
    required this.child,
    this.tier = CardTier.elite,
    this.onTap,
    this.glass = true,
    this.useBlur = false,
  });

  GlowTier _toGlowTier() {
    switch (tier) {
      case CardTier.apex:
        return GlowTier.apex;
      case CardTier.elite:
        return GlowTier.elite;
      case CardTier.hustler:
        return GlowTier.hustler;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = glass
        ? VSurfacePanel(
            useBlur: useBlur,
            padding: const EdgeInsets.all(VSpacing.md),
            shadows: const [],
            child: child,
          )
        : Padding(padding: const EdgeInsets.all(VSpacing.md), child: child);

    final wrapped = glass
        ? GlowBorder(
            tier: _toGlowTier(),
            borderOnly: true,
            padding: EdgeInsets.zero,
            child: content,
          )
        : GlowBorder(
            tier: _toGlowTier(),
            padding: EdgeInsets.zero,
            child: content,
          );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VRadius.xl),
          child: wrapped,
        ),
      );
    }
    return wrapped;
  }
}
