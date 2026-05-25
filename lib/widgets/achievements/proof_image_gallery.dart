import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/achievement_proof_utils.dart';

/// Horizontal gallery of proof images (network or local file).
class ProofImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double height;

  const ProofImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 176,
  });

  @override
  Widget build(BuildContext context) {
    final urls = httpProofUrls(imageUrls);
    if (urls.isEmpty) return const SizedBox.shrink();

    if (urls.length == 1) {
      return _ProofImage(url: urls.first, height: height, width: double.infinity);
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, _) => const SizedBox(width: VSpacing.sm),
        itemBuilder: (_, i) => _ProofImage(
          url: urls[i],
          height: height,
          width: height * 0.75,
        ),
      ),
    );
  }
}

class _ProofImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;

  const _ProofImage({
    required this.url,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(VRadius.lg),
      child: SizedBox(
        width: width,
        height: height,
        child: url.startsWith('http')
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _Fallback(),
              )
            : File(url).existsSync()
                ? Image.file(File(url), fit: BoxFit.cover)
                : const _Fallback(),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: VColors.surfaceContainerHigh,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: VColors.onSurfaceVariant),
      ),
    );
  }
}
