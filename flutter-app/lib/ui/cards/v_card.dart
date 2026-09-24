import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_tokens.dart';

/// Surface elevation via lightness, not drop shadow (DCX-031).
enum VSurfaceElevation { low, medium, high, floating }

/// Canonical flat Prestige Noir surface card.
///
/// This is the single flat-card primitive — it replaces the former
/// `VSurfaceCard`, `VSurfacePanel` and `GlassPanel`. For raised bento /
/// hero cards use [VPrestigeCard] instead.
class VCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VSurfaceElevation elevation;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;

  const VCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VSpacing.md),
    this.elevation = VSurfaceElevation.medium,
    this.borderRadius,
    this.border,
    this.onTap,
  });

  Color get _surfaceColor => switch (elevation) {
    VSurfaceElevation.low => PrestigeNoir.bg,
    VSurfaceElevation.medium => PrestigeNoir.surface,
    VSurfaceElevation.high => PrestigeNoir.surfaceRaised,
    VSurfaceElevation.floating => PrestigeNoir.chrome,
  };

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(VRadius.bento);
    final card = Container(
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: radius,
        border: border ?? Border.all(color: PrestigeNoir.borderLight),
      ),
      padding: padding,
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: card,
      ),
    );
  }
}
