import 'package:flutter/material.dart';
import '../core/skeleton.dart';

class PostImage extends StatelessWidget {
  final String uri;

  const PostImage({super.key, required this.uri});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        uri,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Skeleton(height: 200);
        },
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}
