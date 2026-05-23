import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/v_tokens.dart';
import '../core/broken_media.dart';
import '../core/shimmer.dart';

/// Network or local file URI for post attachments.
class PostImage extends StatelessWidget {
  final String uri;
  final double height;

  const PostImage({super.key, required this.uri, this.height = 200});

  bool get _isNetwork =>
      uri.startsWith('http://') || uri.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(VRadius.md),
      child: _isNetwork ? _networkImage() : _localImage(),
    );
  }

  Widget _networkImage() {
    return Image.network(
      uri,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Pulse(height: height);
      },
      errorBuilder: (context, error, stackTrace) =>
          BrokenMediaTile(height: height),
    );
  }

  Widget _localImage() {
    return Image.file(
      File(uri),
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          BrokenMediaTile(height: height),
    );
  }
}
