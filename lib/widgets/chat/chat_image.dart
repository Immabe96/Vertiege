import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/v_tokens.dart';
import '../core/broken_media.dart';
import '../core/shimmer.dart';

class ChatImage extends StatelessWidget {
  final String url;

  const ChatImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          // B-11 FIX: Added loadingBuilder with shimmer placeholder
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              height: 160,
              width: double.infinity,
              child: Center(
                child: Pulse(
                  height: 160,
                  borderRadius: VRadius.lg,
                  opacity: 0.3,
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => const BrokenMediaTile(height: 160),
        ),
      );
    }
    final file = File(url);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: Image.file(file, fit: BoxFit.cover),
      );
    }
    return const BrokenMediaTile(height: 160);
  }
}
