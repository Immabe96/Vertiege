import 'package:flutter/material.dart';

import '../../utils/asset_image_decode.dart';

/// Renders badge/achievement PNGs with optional light-matte removal on dark UI.
class BadgeAssetImage extends StatelessWidget {
  final String imagePath;
  final double size;
  final BoxFit fit;

  /// When true (default), light PNG mattes are softened on dark theme without crushing colors.
  final bool adaptDarkBackground;
  final ImageErrorWidgetBuilder? errorBuilder;

  const BadgeAssetImage({
    super.key,
    required this.imagePath,
    required this.size,
    this.fit = BoxFit.contain,
    this.adaptDarkBackground = true,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Parent should supply a tinted circle; never multiply-blend on dark UI.
    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.high,
      cacheWidth: assetCachePx(context, size),
      errorBuilder: errorBuilder,
    );
  }
}
