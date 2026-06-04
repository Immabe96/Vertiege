import 'package:flutter/painting.dart';

/// Central limits for in-memory decoded images (Wave 21).
abstract final class ImageCachePolicy {
  static const int maxImages = 200;
  static const int maxBytes = 80 * 1024 * 1024;

  static void apply() {
    final cache = PaintingBinding.instance.imageCache;
    cache.maximumSize = maxImages;
    cache.maximumSizeBytes = maxBytes;
  }
}
