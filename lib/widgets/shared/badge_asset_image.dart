import 'package:flutter/material.dart';

import '../../theme/v_tokens.dart';
import '../../utils/asset_image_decode.dart';

/// Renders badge/achievement PNGs inside a normalized square frame.
///
/// Sizes raster art to [VBadgeSize.artFillFraction] of [size] for consistent
/// optical weight without shrinking the emblem too much.
class BadgeAssetImage extends StatelessWidget {
  final String imagePath;
  final double size;
  final BoxFit fit;

  final ImageErrorWidgetBuilder? errorBuilder;

  const BadgeAssetImage({
    super.key,
    required this.imagePath,
    required this.size,
    this.fit = BoxFit.contain,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final inset = VBadgeSize.artInset(size);
    final inner = VBadgeSize.artInner(size);

    return SizedBox(
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: Image.asset(
          imagePath,
          width: inner,
          height: inner,
          fit: fit,
          filterQuality: FilterQuality.high,
          cacheWidth: assetCachePx(context, inner),
          errorBuilder: errorBuilder,
        ),
      ),
    );
  }
}
