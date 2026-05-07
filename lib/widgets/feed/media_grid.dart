import 'package:flutter/material.dart';
import '../../theme/design_system.dart';
import '../core/shimmer.dart';

class MediaGrid extends StatelessWidget {
  final List<String> images;
  final ValueChanged<String>? onImagePress;

  const MediaGrid({super.key, required this.images, this.onImagePress});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Spacing.xs,
        mainAxisSpacing: Spacing.xs,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: onImagePress != null ? () => onImagePress!(images[index]) : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RadiusTokens.card),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Pulse();
              },
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
