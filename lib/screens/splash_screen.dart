import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _textFade;
  late final Animation<double> _taglineFade;
  late final Animation<double> _loaderFade;
  late final Animation<double> _shapesFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _shapesFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.55, curve: Curves.elasticOut),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
      ),
    );

    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
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
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/generated/bg-splash.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.canvas.withValues(alpha: 0.65),
                    AppColors.canvas.withValues(alpha: 0.8),
                    AppColors.canvas,
                  ],
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildDecorativeShapes(),
                  child!,
                ],
              ),
            ),
          );
        },
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Brand icon — gold gradient on obsidian
              Transform.scale(
                scale: _iconScale.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceElevated.withValues(alpha: 0.72),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.tertiary.withValues(
                          alpha: 0.45 * _iconScale.value,
                        ),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.sm),
                    child: Image.asset(
                      'assets/images/splash-icon.png',
                      fit: BoxFit.contain,
                      cacheWidth: 180,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),
              // App name
              Opacity(
                opacity: _textFade.value,
                child: const Text(
                  'Vertiege',
                  style: TextStyle(
                    fontSize: FontSizes.displayHero,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                    letterSpacing: LetterSpacing.display,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              // Tagline — gold tint
              Opacity(
                opacity: _taglineFade.value,
                child: Text(
                  'Your tier-gated social universe',
                  style: TextStyle(
                    fontSize: FontSizes.body,
                    color: AppColors.tertiary.withValues(alpha: 0.6),
                    letterSpacing: LetterSpacing.micro,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xxl + Spacing.lg),
              // Loading indicator — gold accent
              Opacity(
                opacity: _loaderFade.value,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(
                      AppColors.tertiary.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeShapes() {
    return Opacity(
      opacity: _shapesFade.value,
      child: const Stack(
        children: [
          // Top-right large shape — gold
          Positioned(
            top: -120,
            right: -80,
            child: _DecoShape(size: 400, rotation: 0.4, color: AppColors.tertiary, opacity: 0.08),
          ),
          // Bottom-left medium shape — primary violet
          Positioned(
            bottom: -100,
            left: -60,
            child: _DecoShape(size: 300, rotation: -0.6, color: AppColors.primary, opacity: 0.07),
          ),
          // Top-left small shape — gold
          Positioned(
            top: 80,
            left: -40,
            child: _DecoShape(size: 200, rotation: 0.8, color: AppColors.tertiaryFixedDim, opacity: 0.06),
          ),
          // Bottom-right small shape — violet
          Positioned(
            bottom: 180,
            right: -50,
            child: _DecoShape(size: 180, rotation: -0.3, color: AppColors.primaryFixedDim, opacity: 0.06),
          ),
        ],
      ),
    );
  }
}

/// A rounded decorative shape with rotation and translucent color.
class _DecoShape extends StatelessWidget {
  final double size;
  final double rotation;
  final Color color;
  final double opacity;

  const _DecoShape({
    required this.size,
    required this.rotation,
    required this.color,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation * math.pi,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
      ),
    );
  }
}
