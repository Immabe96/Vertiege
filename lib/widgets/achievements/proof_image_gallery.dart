import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../utils/achievement_proof_utils.dart';
import '../core/image_viewer.dart';

/// Horizontal gallery of proof images (network or local file).
class ProofImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double height;
  final bool enableZoom;

  const ProofImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 176,
    this.enableZoom = true,
  });

  @override
  Widget build(BuildContext context) {
    final urls = httpProofUrls(imageUrls);
    if (urls.isEmpty) return const SizedBox.shrink();

    if (urls.length == 1) {
      return _ProofImage(
        url: urls.first,
        height: height,
        width: double.infinity,
        enableZoom: enableZoom,
        heroTag: 'proof-${urls.first.hashCode}',
      );
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
          enableZoom: enableZoom,
          heroTag: 'proof-${urls[i].hashCode}-$i',
        ),
      ),
    );
  }
}

class _ProofImage extends StatelessWidget {
  final String url;
  final double height;
  final double width;
  final bool enableZoom;
  final String? heroTag;

  const _ProofImage({
    required this.url,
    required this.height,
    required this.width,
    this.enableZoom = true,
    this.heroTag,
  });

  void _openViewer(BuildContext context) {
    if (!enableZoom || !url.startsWith('http')) return;
    ImageViewer.show(context, imageUrl: url, heroTag: heroTag);
  }

  @override
  Widget build(BuildContext context) {
    final image = url.startsWith('http')
        ? Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _Fallback(),
          )
        : File(url).existsSync()
            ? Image.file(File(url), fit: BoxFit.cover)
            : const _Fallback();

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(VRadius.lg),
      child: SizedBox(width: width, height: height, child: image),
    );

    if (enableZoom && url.startsWith('http')) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openViewer(context),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(VSpacing.xs),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: VColors.scrimDark.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.zoom_out_map,
                        size: VIconSize.sm,
                        color: VColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return content;
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
