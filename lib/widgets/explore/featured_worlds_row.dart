import 'package:flutter/material.dart';
import '../../models/world.dart';
import '../../theme/v_tokens.dart';
import '../worlds/world_card.dart';

class FeaturedWorldsRow extends StatelessWidget {
  final List<World> worlds;

  const FeaturedWorldsRow({super.key, required this.worlds});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
        itemCount: worlds.length,
        separatorBuilder: (_, _) => const SizedBox(width: VSpacing.md),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 180,
            child: WorldCard(world: worlds[index], index: index),
          );
        },
      ),
    );
  }
}
