import 'package:forui/forui.dart';
import 'package:flutter/material.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';

class BentoGrid extends StatelessWidget {
  final List<BentoCard> cards;
  const BentoGrid({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Padding(

      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.sm,
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
        width = (screenWidth - (2 * Spacing.md) - Spacing.sm) / 2;
        break;
      case BentoSize.medium:
      case BentoSize.large:
      case BentoSize.full:
        width = screenWidth - (2 * Spacing.md);
        break;
    }

    final child = SizedBox(
      width: width,
      child: FCard(
        useBlur: false,

        child: card.child,
      ),
    );

    if (card.onTap != null) {
      return GestureDetector(onTap: card.onTap, child: child);
    }
    return child;
  }
}
