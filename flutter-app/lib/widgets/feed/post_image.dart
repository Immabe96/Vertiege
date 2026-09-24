import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/v_tokens.dart';
import '../../utils/asset_image_decode.dart';
import '../core/broken_media.dart';
import '../core/shimmer.dart';

/// Network or local file URI for post attachments.
class PostImage extends StatelessWidget {
  final String uri;
  final double height;
  final BorderRadius? borderRadius;

  const PostImage({
    super.key,
    required this.uri,
    this.height = 200,
    this.borderRadius,
  });

  bool get _isNetwork =>
      uri.startsWith('http://') || uri.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(VRadius.md),
      child: _isNetwork ? _networkImage(context) : _localImage(context),
    );
  }

  Widget _networkImage(BuildContext context) {
    final cacheW =
        assetCacheWidthForBanner(context, MediaQuery.sizeOf(context).width);
    final cacheH = assetCachePx(context, height, sourceMax: 2048);
    return Image.network(
      uri,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Pulse(height: height);
      },
      errorBuilder: (context, error, stackTrace) =>
          BrokenMediaTile(height: height),
    );
  }

  Widget _localImage(BuildContext context) {
    final cacheW =
        assetCacheWidthForBanner(context, MediaQuery.sizeOf(context).width);
    final cacheH = assetCachePx(context, height, sourceMax: 2048);
    return Image.file(
      File(uri),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) =>
          BrokenMediaTile(height: height),
    );
  }
}
