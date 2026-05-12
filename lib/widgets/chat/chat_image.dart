import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/design_system.dart';
import '../core/broken_media.dart';

class ChatImage extends StatelessWidget {
  final String url;

  const ChatImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const BrokenMediaTile(height: 160),
        ),
      );
    }
    final file = File(url);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(RadiusTokens.card),
        child: Image.file(file, fit: BoxFit.cover),
      );
    }
    return const BrokenMediaTile(height: 160);
  }
}
