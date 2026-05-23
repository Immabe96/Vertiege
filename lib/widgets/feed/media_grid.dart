import 'package:flutter/material.dart';
import '../../theme/v_tokens.dart';
import '../core/broken_media.dart';
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
        crossAxisSpacing: VSpacing.xs,
        mainAxisSpacing: VSpacing.xs,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: onImagePress != null
              ? () => onImagePress!(images[index])
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(VRadius.lg),
            child: Image.network(
              images[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Pulse();
              },
              errorBuilder: (context, error, stackTrace) =>
                  const BrokenMediaTile(label: 'Unavailable'),
            ),
          ),
        );
      },
    );
  }
}
