import 'package:flutter/material.dart';

/// Banner for a world. Uses the generated world-{id}.jpg in assets/generated/.
/// Falls back to a colored placeholder with the world's Material icon.
class WorldBanner extends StatelessWidget {
  final String worldId;
  final double width;
  final double height;

  const WorldBanner({super.key, required this.worldId, this.width = 400, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/generated/world-$worldId.jpg',
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image, size: 48),
      ),
    );
  }
}
