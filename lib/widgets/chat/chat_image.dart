import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/v_tokens.dart';
import '../../utils/asset_image_decode.dart';
import '../core/broken_media.dart';
import '../core/shimmer.dart';

class ChatImage extends StatelessWidget {
  final String url;

  const ChatImage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return _NetworkOrFileImage(url: url);
  }
}

/// 1 / 2 / 3+ image layouts for chat media.
class ChatImageGrid extends StatelessWidget {
  final List<String> urls;

  const ChatImageGrid({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    final unique = urls.where((u) => u.trim().isNotEmpty).toSet().toList();
    if (unique.isEmpty) return const SizedBox.shrink();
    if (unique.length == 1) {
      return ChatImage(url: unique.first);
    }
    if (unique.length == 2) {
      return Row(
        children: unique
            .map(
              (u) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _NetworkOrFileImage(url: u),
                  ),
                ),
              ),
            )
            .toList(),
      );
    }
    if (unique.length == 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AspectRatio(
              aspectRatio: 1,
              child: _NetworkOrFileImage(url: unique[0]),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _NetworkOrFileImage(url: unique[1]),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: _NetworkOrFileImage(url: unique[2]),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final count = math.min(unique.length, 4);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - 2) / 2;
        return Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            for (var i = 0; i < count; i++)
              SizedBox(
                width: cell,
                height: cell,
                child: i == 3 && unique.length > 4
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _NetworkOrFileImage(url: unique[i]),
                          Container(
                            color: Colors.black54,
                            alignment: Alignment.center,
                            child: Text(
                              '+${unique.length - 4}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: VFontSize.headlineSm,
                              ),
                            ),
                          ),
                        ],
                      )
                    : _NetworkOrFileImage(url: unique[i]),
              ),
          ],
        );
      },
    );
  }
}

class _NetworkOrFileImage extends StatelessWidget {
  final String url;

  const _NetworkOrFileImage({required this.url});

  int _cacheWidth(BuildContext context) {
    final maxBubble = MediaQuery.sizeOf(context).width * 0.75;
    return assetCachePx(context, maxBubble);
  }

  @override
  Widget build(BuildContext context) {
    final cacheWidth = _cacheWidth(context);
    if (url.startsWith('https://') || url.startsWith('http://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          cacheWidth: cacheWidth,
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
        child: Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          cacheWidth: cacheWidth,
        ),
      );
    }
    return const BrokenMediaTile(height: 160);
  }
}

/// Collect image URLs from a channel message.
List<String> imageUrlsForMessage({
  required String? imageUrl,
  required String content,
}) {
  final urls = <String>[];
  if (imageUrl != null && imageUrl.isNotEmpty) {
    urls.add(imageUrl);
  }
  for (final u in VMessageContentImageUrls.fromContent(content)) {
    if (!urls.contains(u)) urls.add(u);
  }
  return urls;
}

/// Avoid circular import — duplicate thin helper.
abstract final class VMessageContentImageUrls {
  static final _urlPattern = RegExp(r'https?://[^\s<>]+', caseSensitive: false);

  static List<String> fromContent(String content) {
    return _urlPattern
        .allMatches(content)
        .map((m) => m.group(0)!)
        .where((url) {
          final lower = url.toLowerCase();
          return lower.endsWith('.png') ||
              lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.gif') ||
              lower.endsWith('.webp') ||
              lower.contains('giphy.com') ||
              lower.contains('tenor.com');
        })
        .toList();
  }
}
