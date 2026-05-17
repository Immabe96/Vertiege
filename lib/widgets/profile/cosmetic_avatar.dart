import 'dart:io';
import 'package:flutter/material.dart';
import '../../config/cosmetics.dart';
import '../../models/avatar_frame.dart';
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

class CosmeticAvatar extends StatefulWidget {
  final int totalXp;
  final double size;
  final String? imageUrl;
  final String? seed;
  final String? frameId;

  const CosmeticAvatar({
    super.key,
    this.totalXp = 0,
    this.size = 48,
    this.imageUrl,
    this.seed,
    this.frameId,
  });

  @override
  State<CosmeticAvatar> createState() => _CosmeticAvatarState();
}

class _CosmeticAvatarState extends State<CosmeticAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AvatarFrame? avatarFrame = widget.frameId != null
        ? AvatarFrame.getById(widget.frameId!)
        : null;
    final xpFrame = getFrameForXp(widget.totalXp);
    final cacheWidth = (widget.size * MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(64, 512);

    final effectiveColor = avatarFrame?.color ?? xpFrame.color;
    final effectiveShadowOpacity = avatarFrame != null ? 0.4 : xpFrame.shadowOpacity;
    final effectiveShadowRadius = avatarFrame != null ? 8.0 : xpFrame.shadowRadius;
    final effectiveGradient = avatarFrame?.gradient;

    final frameColor = effectiveColor is Color
        ? effectiveColor as Color
        : Color(int.parse('FF$effectiveColor', radix: 16));

    Widget avatar = Container(
      width: widget.size + 4,
      height: widget.size + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: frameColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: frameColor.withValues(alpha: effectiveShadowOpacity),
            blurRadius: effectiveShadowRadius,
            spreadRadius: 1,
          ),
        ],
      ),
      child: CircleAvatar(
        radius: widget.size / 2,
        backgroundImage: ResizeImage(
          _resolveImage(widget.imageUrl, widget.seed ?? '${widget.totalXp}'),
          width: cacheWidth,
        ),
      ),
    );

    if (widget.frameId != null && effectiveGradient != null) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: widget.size + 8,
              height: widget.size + 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    frameColor.withValues(alpha: 0.9),
                    frameColor.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: frameColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: child!,
              ),
            ),
          );
        },
        child: avatar,
      );
    }

    return avatar;
  }
}
