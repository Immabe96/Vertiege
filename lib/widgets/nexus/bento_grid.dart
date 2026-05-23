import 'package:flutter/material.dart';
import '../../theme/v_tokens.dart';
import '../core/glass_panel.dart';

class BentoGrid extends StatelessWidget {
  final List<BentoCard> cards;
  const BentoGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
      child: Wrap(
        spacing: VSpacing.sm,
        runSpacing: VSpacing.sm,
        children: cards.map((card) => _BentoCardTile(card: card)).toList(),
      ),
    );
  }
}

class BentoCard {
  final Widget child;
  final BentoSize size;
  final VoidCallback? onTap;
  const BentoCard({
    required this.child,
    this.size = BentoSize.small,
    this.onTap,
  });
}

enum BentoSize { small, medium, large, full }

class _BentoCardTile extends StatelessWidget {
  final BentoCard card;
  const _BentoCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double width;
    switch (card.size) {
      case BentoSize.small:
        width = (screenWidth - (2 * VSpacing.md) - VSpacing.sm) / 2;
        break;
      case BentoSize.medium:
      case BentoSize.large:
      case BentoSize.full:
        width = screenWidth - (2 * VSpacing.md);
        break;
    }

    final minHeight = card.size == BentoSize.small ? 148.0 : null;
    final child = SizedBox(
      width: width,
      height: minHeight,
      child: VSurfacePanel(
        useBlur: false,
        padding: const EdgeInsets.all(VSpacing.md),
        child: card.child,
      ),
    );

    if (card.onTap != null) {
      return GestureDetector(onTap: card.onTap, child: child);
    }
    return child;
  }
}
