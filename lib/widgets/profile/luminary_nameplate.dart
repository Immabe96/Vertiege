import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';

/// A tier-aware nameplate that renders resident names with progressive
/// visual prestige based on their tier level.
///
/// Tier 1 (Hustler,       0-499 XP):   Plain text, ink color
/// Tier 2 (High Roller,   500-1999 XP): SemiBold, primary color
/// Tier 3 (Elite,         2000-9999 XP): Bold, subtle violet glow shadow
/// Tier 4 (Old Money,     10000-49999 XP): Gold text, glow shadow
/// Tier 5 (Apex,          50000+ XP):   Animated gold-violet gradient with glow
class LuminaryNameplate extends StatelessWidget {
  final String name;
  final int tier;
  final double fontSize;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;
  final String? title;

  const LuminaryNameplate({
    super.key,
    required this.name,
    this.tier = 1,
    this.fontSize = FontSizes.bodyLg,
    this.textAlign = TextAlign.left,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty) {
      return Text(
        'Traveler',
        style: _buildStyle(tier),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Tier 5 (Apex) gets animated gradient
    if (tier >= 5) {
      return _buildTitledNameplate(
        _ApexNameplate(
          name: name,
          fontSize: fontSize,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      );
    }

    return _buildTitledNameplate(
      Text(
        name,
        style: _buildStyle(tier),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }

  Widget _buildTitledNameplate(Widget nameWidget) {
    if (title == null) return nameWidget;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        nameWidget,
        Text(
          title!,
          style: TextStyle(
            fontSize: fontSize * 0.75,
            fontStyle: FontStyle.italic,
            color: AppColors.inkSecondary,
          ),
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  TextStyle _buildStyle(int tier) {
    final baseStyle = GoogleFonts.spaceGrotesk(fontSize: fontSize);

    switch (tier) {
      case 5:
      case 4:
        // Old Money / Apex: Gold text with glow
        return baseStyle.copyWith(
          fontWeight: FontWeights.bold,
          color: AppColors.tertiary,
          shadows: [
            Shadow(
              color: AppColors.tertiary.withValues(alpha: 0.3),
              blurRadius: 12,
            ),
          ],
        );
      case 3:
        // Elite: Bold with subtle violet glow
        return baseStyle.copyWith(
          fontWeight: FontWeights.bold,
          color: AppColors.primary,
          shadows: [
            Shadow(
              color: AppColors.primary.withValues(alpha: 0.2),
              blurRadius: 8,
            ),
          ],
        );
      case 2:
        // High Roller: SemiBold, primary color
        return baseStyle.copyWith(
          fontWeight: FontWeights.semiBold,
          color: AppColors.primary,
        );
      case 1:
      default:
        // Hustler: Plain text, ink color
        return baseStyle.copyWith(
          fontWeight: FontWeights.regular,
          color: AppColors.ink,
        );
    }
  }
}

/// Animated gold-violet gradient nameplate for Apex tier (Tier 5).
class _ApexNameplate extends StatefulWidget {
  final String name;
  final double fontSize;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;

  const _ApexNameplate({
    required this.name,
    required this.fontSize,
    required this.textAlign,
    required this.maxLines,
    required this.overflow,
  });

  @override
  State<_ApexNameplate> createState() => _ApexNameplateState();
}

class _ApexNameplateState extends State<_ApexNameplate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween(begin: 0.0, end: 1.0).animate(
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
    final baseStyle = GoogleFonts.spaceGrotesk(
      fontSize: widget.fontSize,
      fontWeight: FontWeights.bold,
      color: Colors.white,
    );

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            final shift = _animation.value;
            return LinearGradient(
              colors: const [
                AppColors.tertiary,
                AppColors.primary,
                AppColors.tertiary,
                AppColors.primary,
              ],
              stops: [
                0.0,
                0.25 + shift * 0.1,
                0.5 + shift * 0.1,
                1.0,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            widget.name,
            style: baseStyle,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
          ),
        );
      },
    );
  }
}
