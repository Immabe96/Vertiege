import 'package:flutter/material.dart';

import '../../utils/asset_image_decode.dart';

/// Renders badge/achievement PNGs; removes light matte on dark backgrounds.
class BadgeAssetImage extends StatelessWidget {
  final String imagePath;
  final double size;
  final BoxFit fit;
  /// Background behind the image in dark mode (for [BlendMode.multiply] matting).
  final Color? darkMatteColor;
  final ImageErrorWidgetBuilder? errorBuilder;

  const BadgeAssetImage({
    super.key,
    required this.imagePath,
    required this.size,
    this.fit = BoxFit.contain,
    this.darkMatteColor,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final matte = isDark
        ? (darkMatteColor ?? theme.colorScheme.surface)
        : null;

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
      cacheWidth: assetCachePx(context, size),
      color: matte,
      colorBlendMode: isDark ? BlendMode.multiply : null,
      errorBuilder: errorBuilder,
    );
  }
}
