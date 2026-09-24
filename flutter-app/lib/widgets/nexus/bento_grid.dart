import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_tokens.dart';

class BentoGrid extends StatelessWidget {
  final List<BentoCard> cards;

  /// Flatter activity rows — less glass chrome (DCX-087).
  final bool flat;

  const BentoGrid({
    super.key,
    required this.cards,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0 || cards.isEmpty) {
          return const SizedBox.shrink();
        }

        const spacing = VSpacing.sm;
        final cellWidth = (maxWidth - spacing) / 2;
        final rows = _packRows(cards);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: spacing),
              _BentoRow(
                row: rows[i],
                cellWidth: cellWidth,
                spacing: spacing,
                flat: flat,
              ),
            ],
          ],
        );
      },
    );
  }

  /// Packs cards into rows of two column-slots (wide cards span both).
  static List<List<BentoCard>> _packRows(List<BentoCard> cards) {
    final rows = <List<BentoCard>>[];
    var current = <BentoCard>[];
    var slots = 0;

    void flush() {
      if (current.isEmpty) return;
      rows.add(List<BentoCard>.from(current));
      current = [];
      slots = 0;
    }

    for (final card in cards) {
      final span = _columnSpan(card.size);
      if (slots > 0 && slots + span > 2) {
        flush();
      }
      current.add(card);
      slots += span;
      if (slots >= 2) {
        flush();
      }
    }
    flush();
    return rows;
  }

  static int _columnSpan(BentoSize size) =>
      size == BentoSize.small ? 1 : 2;
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

class _BentoRow extends StatelessWidget {
  final List<BentoCard> row;
  final double cellWidth;
  final double spacing;
  final bool flat;

  const _BentoRow({
    required this.row,
    required this.cellWidth,
    required this.spacing,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final fullWidth = cellWidth * 2 + spacing;
    final height = _rowHeight(row);

    // One card in the row — use full width (no empty half-column gap).
    if (row.length == 1) {
      return _BentoCardTile(
        card: row.first,
        width: fullWidth,
        height: height,
        flat: flat,
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < row.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(
              child: _BentoCardTile(
                card: row[i],
                width: cellWidth,
                height: height,
                flat: flat,
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _rowHeight(List<BentoCard> row) {
    var maxH = 164.0;
    for (final card in row) {
      maxH = maxH > _heightFor(card.size) ? maxH : _heightFor(card.size);
    }
    return maxH;
  }

  double _heightFor(BentoSize size) {
    if (flat) {
      return switch (size) {
        BentoSize.small => 132,
        BentoSize.medium => 148,
        BentoSize.large => 168,
        BentoSize.full => 168,
      };
    }
    return switch (size) {
      BentoSize.small => 164,
      BentoSize.medium => 184,
      BentoSize.large => 212,
      BentoSize.full => 212,
    };
  }
}

class _BentoCardTile extends StatelessWidget {
  final BentoCard card;
  final double width;
  final double height;
  final bool flat;

  const _BentoCardTile({
    required this.card,
    required this.width,
    required this.height,
    this.flat = false,
  });

  @override
  Widget build(BuildContext context) {
    final padding = flat ? VSpacing.sm : VSpacing.md;
    final innerHeight = height - (padding * 2);
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: PrestigeNoir.surfaceRaised,
        borderRadius: BorderRadius.circular(VRadius.bento),
        border: Border.all(color: PrestigeNoir.borderLight),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: ClipRect(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width - (padding * 2),
              height: innerHeight,
              child: card.child,
            ),
          ),
        ),
      ),
    );
    final child = SizedBox(
      width: width,
      height: height,
      child: surface,
    );

    if (card.onTap != null) {
      return GestureDetector(onTap: card.onTap, child: child);
    }
    return child;
  }
}
