import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class ProgressTrail extends StatefulWidget {
  final int currentTier;
  const ProgressTrail({super.key, required this.currentTier});

  static const _tierNames = [
    'Hustler',
    'High Roller',
    'Elite',
    'Old Money',
    'Apex',
  ];

  static const _tierColors = [
    VColors.tierHustler,
    VColors.tierHighRoller,
    VColors.tierElite,
    VColors.tierOldMoney,
    VColors.tierApex,
  ];

  @override
  State<ProgressTrail> createState() => _ProgressTrailState();
}

class _ProgressTrailState extends State<ProgressTrail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: CustomPaint(
        size: Size.infinite,
        painter: _TrailPathPainter(currentTier: widget.currentTier),
      ),
    );
  }
}

class _TrailPathPainter extends CustomPainter {
  final int currentTier;
  _TrailPathPainter({required this.currentTier});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final nodeRadius = 32.0;

    // 5 nodes distributed across the canvas in a winding path
    final positions = <Offset>[
      Offset(width * 0.1, height * 0.75),
      Offset(width * 0.3, height * 0.25),
      Offset(width * 0.5, height * 0.65),
      Offset(width * 0.7, height * 0.2),
      Offset(width * 0.9, height * 0.5),
    ];

    // Draw path lines between nodes
    for (int i = 0; i < positions.length - 1; i++) {
      final from = positions[i];
      final to = positions[i + 1];
      final isCompleted = i + 1 < currentTier;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;

      if (isCompleted) {
        paint.shader = LinearGradient(
          colors: [
            ProgressTrail._tierColors[i],
            ProgressTrail._tierColors[i + 1],
          ],
        ).createShader(Rect.fromPoints(from, to));
      } else {
        paint.color = VColors.glassBorder;
      }

      canvas.drawLine(from, to, paint);
    }

    // Draw nodes
    for (int i = 0; i < positions.length; i++) {
      final pos = positions[i];
      final tierIndex = i + 1;
      final isCompleted = tierIndex < currentTier;
      final isCurrent = tierIndex == currentTier;
      final isFuture = tierIndex > currentTier;

      // Glow ring for completed nodes
      if (isCompleted) {
        final glowPaint = Paint()
          ..color = ProgressTrail._tierColors[i].withValues(alpha: 0.15)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(pos, nodeRadius + 6, glowPaint);
      }

      // Pulsing glow for current node
      if (isCurrent) {
        final glowPaint = Paint()
          ..color = VColors.primary.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
        canvas.drawCircle(pos, nodeRadius + 8, glowPaint);
      }

      // Node circle background
      final bgColor = isFuture
          ? VColors.surfaceContainerHighest
          : ProgressTrail._tierColors[i].withValues(alpha: 0.12);
      final bgPaint = Paint()..color = bgColor;
      canvas.drawCircle(pos, nodeRadius, bgPaint);

      // Node border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      if (isCompleted) {
        borderPaint.color = ProgressTrail._tierColors[i];
      } else if (isCurrent) {
        borderPaint.color = VColors.primary;
      } else {
        borderPaint.color = VColors.glassBorder;
      }
      canvas.drawCircle(pos, nodeRadius, borderPaint);

      // Draw tier icon inside node
      final iconText = _tierIconForIndex(i);
      final textPainter = TextPainter(
        text: TextSpan(
          text: iconText,
          style: TextStyle(
            fontSize: VFontSize.headlineSm,
            color: isFuture ? VColors.outline : ProgressTrail._tierColors[i],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2),
      );

      // Draw tier label below node
      final labelColor = isFuture
          ? VColors.outline
          : isCurrent
          ? VColors.primary
          : VColors.onSurfaceVariant;
      final labelPainter = TextPainter(
        text: TextSpan(
          text: ProgressTrail._tierNames[i],
          style: TextStyle(
            fontSize: isCurrent ? 11 : 10,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(pos.dx - labelPainter.width / 2, pos.dy + nodeRadius + 8),
      );

      // "CURRENT" label for current node
      if (isCurrent) {
        final currentPainter = TextPainter(
          text: const TextSpan(
            text: 'CURRENT',
            style: TextStyle(
              fontSize: VFontSize.labelSm,
              fontWeight: FontWeight.w700,
              color: VColors.primary,
              letterSpacing: 0.05,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        currentPainter.layout();
        currentPainter.paint(
          canvas,
          Offset(pos.dx - currentPainter.width / 2, pos.dy + nodeRadius + 22),
        );
      }
    }
  }

  String _tierIconForIndex(int index) {
    // Single-char icons for canvas rendering
    return switch (index) {
      0 => '?', // ? triangle
      1 => '?', // ? diamond
      2 => '?', // ? star
      3 => '?', // ? shield
      4 => '?', // ? flag
      _ => '?', // ? circle
    };
  }

  @override
  bool shouldRepaint(covariant _TrailPathPainter oldDelegate) {
    return oldDelegate.currentTier != currentTier;
  }
}
