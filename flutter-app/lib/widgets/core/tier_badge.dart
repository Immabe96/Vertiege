import 'package:flutter/material.dart';

import '../shared/tier_icon.dart';

/// Compact tier mark shown next to resident names.
///
/// Uses the generated tier art via [TierIcon] (not Material icon fallbacks).
class TierBadge extends StatelessWidget {
  final int tier;
  final double size;

  const TierBadge({super.key, required this.tier, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return TierIcon(tier: tier, size: size);
  }
}
