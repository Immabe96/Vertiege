import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WorldBanner extends StatelessWidget {
  final String worldId;
  final double width;
  final double height;

  const WorldBanner({super.key, required this.worldId, this.width = 400, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/banners/$worldId-banner.svg',
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholderBuilder: (_) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image, size: 48),
      ),
    );
  }
}
