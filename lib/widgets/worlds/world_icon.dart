import 'package:flutter/material.dart';

class WorldIcon extends StatelessWidget {
  final String worldId;
  final double size;

  const WorldIcon({super.key, required this.worldId, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final icon = _iconForWorld(worldId);
    return Icon(icon, size: size, color: Theme.of(context).colorScheme.primary);
  }

  static IconData _iconForWorld(String worldId) {
    return switch (worldId) {
      'neon-district' => Icons.nights_stay,
      'azure-coast' => Icons.beach_access,
      'sovereign-city' => Icons.account_balance,
      'golden-estate' => Icons.villa,
      'aetheria' => Icons.cloud,
      'aviation-heights' => Icons.flight,
      'medical-nexus' => Icons.local_hospital,
      'financial-district' => Icons.attach_money,
      'tech-sprawl' => Icons.computer,
      'legal-plaza' => Icons.gavel,
      'arts-pavilion' => Icons.palette,
      'crystal-shore' => Icons.diamond,
      'quantum-core' => Icons.science,
      'silver-page' => Icons.menu_book,
      'crimson-court' => Icons.castle,
      'nova-station' => Icons.rocket_launch,
      _ => Icons.public,
    };
  }
}
