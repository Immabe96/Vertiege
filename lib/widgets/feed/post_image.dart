import 'package:flutter/material.dart';
import '../../theme/design_system.dart';
import '../core/broken_media.dart';
import '../core/shimmer.dart';

class PostImage extends StatelessWidget {
  final String uri;

  const PostImage({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(RadiusTokens.cardFeatured),
      child: Image.network(
        uri,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Pulse(height: 200);
        },
        errorBuilder: (context, error, stackTrace) =>
            const BrokenMediaTile(height: 200),
      ),
    );
  }
}
