import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/world.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';

/// AI-assisted banner generator that creates 4 procedural variants
/// seeded deterministically from the world's ID and properties.
class BannerGenerator extends StatefulWidget {
  final String worldId;
  final String worldName;
  final WorldType worldType;
  final int prestige;
  final String description;
  final void Function(int variant) onSelect;

  const BannerGenerator({
    super.key,
    required this.worldId,
    required this.worldName,
    required this.worldType,
    required this.prestige,
    required this.description,
    required this.onSelect,
  });

  @override
  State<BannerGenerator> createState() => _BannerGeneratorState();
}

class _BannerGeneratorState extends State<BannerGenerator> {
  bool _generating = true;

  @override
  void initState() {
    super.initState();
    _simulateGeneration();
  }

  Future<void> _simulateGeneration() async {
    // Simulate AI generation delay
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_generating) {
      return _GeneratingState();
    }

    final variants = _generateVariants();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: Spacing.sm,
        mainAxisSpacing: Spacing.sm,
      ),
      itemCount: variants.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => widget.onSelect(index),
          child: GlassPanel(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(RadiusTokens.xl),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _VariantPainter(
                      seed: widget.worldId.hashCode + index * 137,
                      worldType: widget.worldType,
                      prestige: widget.prestige,
                      variantIndex: index,
                    ),
                  ),
                  // Variant label
                  Positioned(
                    bottom: Spacing.xs,
                    right: Spacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.canvas.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(RadiusTokens.sm),
                      ),
                      child: Text(
                        'Variant ${index + 1}',
                        style: const TextStyle(
                          fontSize: FontSizes.micro,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<_Variant> _generateVariants() {
    return List.generate(4, (i) => _Variant(index: i));
  }
}

class _GeneratingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseWidget(
            child: const Icon(Icons.auto_awesome, size: IconSizes.hero, color: AppColors.tertiary),
          ),
          const SizedBox(height: Spacing.lg),
          const Text(
            'The Herald is generating banner variants...',
            style: TextStyle(
              fontSize: FontSizes.bodyMd,
              color: AppColors.inkSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.sm),
          const Text(
            'Analyzing world aesthetics and prestige patterns.',
            style: TextStyle(
              fontSize: FontSizes.labelSm,
              color: AppColors.inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Pulse animation for the generating state.
class _PulseWidget extends StatefulWidget {
  final Widget child;
  const _PulseWidget({required this.child});

  @override
  State<_PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<_PulseWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.6, end: 1.0).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

// ── Variant model ────────────────────────────────────────

class _Variant {
  final int index;
  const _Variant({required this.index});
}

// ── Procedural variant painter ────────────────────────────

class _VariantPainter extends CustomPainter {
  final int seed;
  final WorldType worldType;
  final int prestige;
  final int variantIndex;

  _VariantPainter({
    required this.seed,
    required this.worldType,
    required this.prestige,
    required this.variantIndex,
  });

  Color get _tierColor {
    if (prestige >= 600) return AppColors.tertiary;
    if (prestige >= 300) return AppColors.primary;
    return AppColors.hustler;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);

    // Background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.canvas,
          Color.lerp(AppColors.surface, _tierColor, 0.05 + variantIndex * 0.02)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Pattern variation based on variant index
    final patternPaint = Paint()
      ..color = _tierColor.withValues(alpha: 0.08 + variantIndex * 0.02)
      ..strokeWidth = 1.0;

    switch (variantIndex) {
      case 0: // Diagonal lines
        for (double d = 0; d < size.width + size.height; d += 12 + rng.nextDouble() * 8) {
          canvas.drawLine(
            Offset(d > size.width ? size.width : d, d > size.width ? d - size.width : 0),
            Offset(d > size.height ? d - size.height : 0, d > size.height ? size.height : d),
            patternPaint,
          );
        }
        break;
      case 1: // Concentric circles
        for (double r = 10; r < size.width; r += 15 + rng.nextDouble() * 10) {
          canvas.drawCircle(
            Offset(size.width / 2, size.height / 2),
            r,
            patternPaint,
          );
        }
        break;
      case 2: // Hexagonal grid
        final step = size.width / 5;
        for (double x = 0; x < size.width + step; x += step * 1.5) {
          for (double y = 0; y < size.height + step; y += step * 0.55) {
            final offset = (y ~/ (step * 0.55).round() % 2 == 0) ? 0.0 : step * 0.75;
            _drawHex(canvas, Offset(x + offset, y), step / 3, patternPaint);
          }
        }
        break;
      case 3: // Radiating lines from center
        final center = Offset(size.width / 2, size.height / 2);
        for (double angle = 0; angle < 3.14159 * 2; angle += 0.2 + rng.nextDouble() * 0.3) {
          canvas.drawLine(
            center,
            Offset(
              center.dx + size.width * math.cos(angle),
              center.dy + size.height * math.sin(angle),
            ),
            patternPaint,
          );
        }
        break;
    }

    // Accent dots
    final dotPaint = Paint()
      ..color = _tierColor.withValues(alpha: 0.15 + variantIndex * 0.05);
    for (int i = 0; i < 6 + variantIndex * 2; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 2 + rng.nextDouble() * 2, dotPaint);
    }

    // Bottom glow
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _tierColor.withValues(alpha: 0.0),
          _tierColor.withValues(alpha: 0.3),
        ],
      ).createShader(Rect.fromLTWH(0, size.height - 4, size.width, 4));
    canvas.drawRect(Rect.fromLTWH(0, size.height - 4, size.width, 4), glowPaint);
  }

  void _drawHex(Canvas canvas, Offset center, double r, Paint paint) {
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
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _VariantPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.variantIndex != variantIndex;
}
