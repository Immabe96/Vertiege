import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/cosmetics.dart';
import '../../utils/world_assets.dart';

ImageProvider _resolveImage(String? url, String seed) {
  if (url == null || url.isEmpty) {
    return AssetImage(WorldAssets.avatarForSeed(seed));
  }
  if (url.startsWith('http')) {
    return NetworkImage(url);
  }
  if (url.startsWith('/') || url.startsWith('C:')) {
    final file = File(url);
    if (file.existsSync()) return FileImage(file);
    return AssetImage(WorldAssets.avatarForSeed(seed));
  }
  if (url.contains('assets/')) {
    return AssetImage(url);
  }
  return AssetImage(WorldAssets.avatarForSeed(seed));
}

class CosmeticAvatar extends StatelessWidget {
  final int totalXp;
  final double size;
  final String? imageUrl;
  final String? seed;

  const CosmeticAvatar({
    super.key,
    this.totalXp = 0,
    this.size = 80,
    this.imageUrl,
    this.seed,
  });

  @override
  Widget build(BuildContext context) {
    final frame = getFrameForXp(totalXp);

    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: frame.color.withValues(alpha: 0.5), width: 3),
        boxShadow: [
          BoxShadow(
            color: frame.color.withValues(alpha: frame.shadowOpacity),
            blurRadius: frame.shadowRadius,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundImage: _resolveImage(imageUrl, seed ?? '$totalXp'),
      ),
    );
  }
}
