import 'package:flutter/material.dart';

/// Target decode width/height for bundled rasters so they stay sharp on screen.
///
/// ChatGPT exports are often 1024px+ even when the manifest says 512x512.
/// Low [Image.cacheWidth] values decode tiny bitmaps that look pixelated when drawn larger.
int assetCachePx(
  BuildContext context,
  double logicalSize, {
  int sourceMax = 1024,
  int minPx = 48,
}) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final target = (logicalSize * dpr).ceil();
  return target.clamp(minPx, sourceMax);
}

/// World banner JPEGs are ~1200–1700px wide.
int assetCacheWidthForBanner(BuildContext context, double logicalWidth) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final w = logicalWidth.isFinite
      ? logicalWidth
      : MediaQuery.sizeOf(context).width;
  return (w * dpr).ceil().clamp(480, 2048);
}

/// Full-bleed phone backgrounds (1080x1920 class assets).
({int width, int height}) assetCacheSizeForCover(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final dpr = MediaQuery.devicePixelRatioOf(context);
  return (
    width: (size.width * dpr).ceil().clamp(720, 2160),
    height: (size.height * dpr).ceil().clamp(1280, 3840),
  );
}
