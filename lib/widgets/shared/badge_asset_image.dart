import 'package:flutter/material.dart';

import '../../theme/v_colors.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Multiply with a dark surface turns full-color badges into solid black blobs.
    // Show assets at full color in dark mode; optional soft matte only on light UI.
    if (!isDark) {
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

    if (!adaptDarkBackground) {
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: VColors.surfaceContainerHighDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: fit,
          filterQuality: FilterQuality.high,
          cacheWidth: assetCachePx(context, size),
          errorBuilder: errorBuilder,
        ),
      ),
    );
  }
}
