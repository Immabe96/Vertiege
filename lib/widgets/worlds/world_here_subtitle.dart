import 'package:flutter/material.dart';

import '../../config/tiers.dart';
import '../../models/world.dart';
import '../../theme/v_context_colors.dart';
import '../../theme/v_tokens.dart';

/// One-line world context under the title (Wave 14 quiet IA).
String worldHereSubtitle({
  required World world,
  required bool isJoined,
  required String tierLabel,
}) {
  final prestige = world.prestige;
  final standing = isJoined ? 'Member' : 'Visitor';
  final gate = tierNames[world.requiredTier] ?? tierLabel;
  return 'Prestige $prestige · $standing · $gate';
}

class WorldHereSubtitleText extends StatelessWidget {
  final World world;
  final bool isJoined;
  final String tierLabel;

  const WorldHereSubtitleText({
    super.key,
    required this.world,
    required this.isJoined,
    required this.tierLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      worldHereSubtitle(
        world: world,
        isJoined: isJoined,
        tierLabel: tierLabel,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.vOnSurfaceVariant,
            height: 1.3,
          ),
    );
  }
}
