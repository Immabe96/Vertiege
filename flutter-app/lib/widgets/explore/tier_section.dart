import 'package:flutter/material.dart';
import '../../models/world.dart';

class TierSection {
  final String title;
  final Color color;
  final List<World> worlds;

  const TierSection({
    required this.title,
    required this.color,
    required this.worlds,
  });
}
