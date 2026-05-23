import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../utils/asset_image_decode.dart';
import '../../utils/world_assets.dart';

/// Procedural world banner that generates a unique, tier-themed visual
/// for every world using a deterministic seed from the world ID.
///
/// Tier colors:
///   prestige >= 600  =>  gold (tertiary)
///   prestige >= 300  =>  violet (primary)
///   prestige <  300  =>  orange (hustler)
class WorldBanner extends StatelessWidget {
  final String worldId;
  final String? assetKey;
  final double width;
  final double height;
  final WorldType worldType;
  final int prestige;

  const WorldBanner({
    super.key,
    required this.worldId,
    this.assetKey,
    this.width = 400,
    this.height = 200,
    this.worldType = WorldType.wealth,
    this.prestige = 0,
  });

  Color get tierColor => WorldAssets.colorForPrestige(prestige);

  @override
  Widget build(BuildContext context) {
    final visualKey = assetKey ?? worldId;
    final imagePath = WorldAssets.imageForWorld(visualKey);
    final logicalCacheWidth = width.isFinite
        ? width
        : MediaQuery.sizeOf(context).width;
    final cacheWidth = assetCacheWidthForBanner(context, logicalCacheWidth);
    if (imagePath != null) {
      return SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              cacheWidth: cacheWidth,
              errorBuilder: (_, _, _) => CustomPaint(
                painter: _WorldBannerPainter(
                  worldId: worldId,
                  worldType: worldType,
                  tierColor: tierColor,
                  prestige: prestige,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _WorldBannerPainter(
          worldId: worldId,
          worldType: worldType,
          tierColor: tierColor,
          prestige: prestige,
        ),
      ),
    );
  }
}

// ── Procedural Painter ────────────────────────────────────────

class _WorldBannerPainter extends CustomPainter {
  final String worldId;
  final WorldType worldType;
  final Color tierColor;
  final int prestige;

  _WorldBannerPainter({
    required this.worldId,
    required this.worldType,
    required this.tierColor,
    required this.prestige,
  });

  // Deterministic variation derived from worldId
  double get _rotation => (worldId.hashCode % 360).toDouble() * math.pi / 180;
  int get _density => 3 + (worldId.hashCode.abs() % 5);
  int get _accentCount => 2 + (worldId.hashCode.abs() % 8);
  IconData get _icon => WorldAssets.iconForWorld(worldId);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBackground(canvas, size);
    _drawPatterns(canvas, size);
    _drawIconSilhouette(canvas, size);
    _drawVignette(canvas, size);
    _drawBottomGlow(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _WorldBannerPainter oldDelegate) =>
      oldDelegate.worldId != worldId ||
      oldDelegate.worldType != worldType ||
      oldDelegate.prestige != prestige;

  // ── Layers ──────────────────────────────────────────────────

  /// Deep dark gradient from canvas to surface.
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [VColors.surface, VColors.surface],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  /// Tier-specific geometric pattern at low opacity.
  void _drawPatterns(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tierColor.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(_rotation);
    canvas.translate(-size.width / 2, -size.height / 2);

    switch (worldType) {
      case WorldType.wealth:
        _drawDiamondGrid(canvas, size, paint);
      case WorldType.profession:
        _drawHexPattern(canvas, size, paint);
      case WorldType.dominion:
        _drawFortressPattern(canvas, size, paint);
    }

    canvas.restore();

    _drawAccentDots(canvas, size);
  }

  /// Diamond / geometric grid for wealth worlds.
  void _drawDiamondGrid(Canvas canvas, Size size, Paint paint) {
    final step = size.width / (_density + 2);
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final path = Path()
          ..moveTo(x, y - step / 3)
          ..lineTo(x + step / 3, y)
          ..lineTo(x, y + step / 3)
          ..lineTo(x - step / 3, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  /// Hexagonal / tech pattern for profession worlds.
  void _drawHexPattern(Canvas canvas, Size size, Paint paint) {
    final step = size.width / (_density + 2);
    final r = step / 2.5;
    for (double x = r; x < size.width + r; x += step * 1.5) {
      for (int i = 0; i < (size.height / (step * 0.55)).ceil(); i++) {
        final offset = (i % 2 == 0) ? 0.0 : step * 0.75;
        final y = r + i * step * 0.55;
        canvas.drawPath(_hexagonPath(Offset(x + offset, y), r), paint);
      }
    }
  }

  Path _hexagonPath(Offset center, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 180 * (60 * i - 30);
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  /// Fortress / arch pattern for dominion worlds.
  void _drawFortressPattern(Canvas canvas, Size size, Paint paint) {
    final step = size.width / (_density + 2);
    for (double x = step / 2; x < size.width; x += step) {
      // Vertical pillars
      canvas.drawLine(
        Offset(x, size.height * 0.15),
        Offset(x, size.height * 0.85),
        paint,
      );
      // Arch cap at top
      final archPath = Path()
        ..moveTo(x - step / 4, size.height * 0.15)
        ..quadraticBezierTo(
          x,
          size.height * 0.15 - step / 3,
          x + step / 4,
          size.height * 0.15,
        );
      canvas.drawPath(archPath, paint);
    }
    // Horizontal connective beams
    final hPaint = Paint()
      ..color = tierColor.withValues(alpha: 0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      hPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.72),
      Offset(size.width, size.height * 0.72),
      hPaint,
    );
  }

  /// Small glowing scatter dots — positions seeded from worldId hash.
  void _drawAccentDots(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tierColor.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final rng = math.Random(worldId.hashCode.abs());
    for (int i = 0; i < _accentCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 2, paint);
    }
  }

  /// Large semi-transparent icon silhouette centered on the banner.
  void _drawIconSilhouette(Canvas canvas, Size size) {
    final iconStr = String.fromCharCode(_icon.codePoint);
    final textPainter = TextPainter(
      text: TextSpan(
        text: iconStr,
        style: TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: size.height * 0.4,
          color: tierColor.withValues(alpha: 0.12),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  /// Subtle vignette overlay at the edges.
  void _drawVignette(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, -0.1),
        radius: 0.9,
        colors: [Colors.transparent, VColors.surface.withValues(alpha: 0.55)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  /// Tier-colored bottom border glow (4 px high).
  void _drawBottomGlow(Canvas canvas, Size size) {
    const glowHeight = 4.0;
    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tierColor.withValues(alpha: 0.0),
              tierColor.withValues(alpha: 0.30),
            ],
          ).createShader(
            Rect.fromLTWH(0, size.height - glowHeight, size.width, glowHeight),
          );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height - glowHeight, size.width, glowHeight),
      paint,
    );
  }
}
