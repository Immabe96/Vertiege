import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/resident.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../theme/v_tokens.dart';
import '../shared/tier_icon.dart';
import '../../ui/buttons/v_button.dart';

class TierCelebration extends StatefulWidget {
  final ResidentTier tier;
  final VoidCallback onDismiss;

  const TierCelebration({
    super.key,
    required this.tier,
    required this.onDismiss,
  });

  @override
  State<TierCelebration> createState() => _TierCelebrationState();
}

const _tierPerks = <ResidentTier, List<String>>{
  ResidentTier.hustlers: [
    'Access to the social feed',
    'Basic profile customization',
    'Join up to 3 worlds',
  ],
  ResidentTier.highRollers: [
    'Custom display badges',
    'Access to exclusive worlds',
    'Priority matchmaking',
    'All Hustler perks',
  ],
  ResidentTier.elite: [
    'Custom profile banners',
    'Create your own world',
    'Early access to new features',
    'All High Roller perks',
  ],
  ResidentTier.oldMoney: [
    'Wealth world access',
    'VIP support channel',
    'Custom title & flair',
    'All Elite perks',
  ],
  ResidentTier.apex: [
    'Apex lounge access',
    'Founder recognition badge',
    'Direct influence on roadmap',
    'All Old Money perks',
  ],
};

class _TierCelebrationState extends State<TierCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _overlayOpacity;

  final _perkAnimations = <int, Animation<double>>{};
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _overlayOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _cardScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.08), weight: 3),
          TweenSequenceItem(tween: Tween(begin: 1.08, end: 0.96), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 1),
        ]).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.15, 0.55, curve: Curves.easeOut),
          ),
        );

    _cardOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.35, curve: Curves.easeOut),
      ),
    );

    final perks = _tierPerks[widget.tier] ?? _tierPerks[ResidentTier.hustlers]!;
    for (int i = 0; i < perks.length; i++) {
      final start = 0.35 + (i * 0.08);
      _perkAnimations[i] = Tween(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            start.clamp(0.0, 0.95),
            (start + 0.12).clamp(0.07, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      );
    }

    _controller.forward();

    // Auto-dismiss after 8 seconds
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_dismissed) _dismiss();
    });
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return PopScope(
          canPop: false,
          child: GestureDetector(
            onTap: _dismiss,
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  // Semi-transparent overlay
                  Opacity(
                    opacity: _overlayOpacity.value,
                    child: Container(
                      color: VColors.scrim,
                    ),
                  ),
                  // Confetti canvas
                  _ConfettiCanvas(controller: _controller),
                  // Centered celebration card
                  Center(
                    child: Opacity(
                      opacity: _cardOpacity.value,
                      child: Transform.scale(
                        scale: _cardScale.value,
                        child: _CelebrationCard(
                          tier: widget.tier,
                          perkAnimations: _perkAnimations,
                          onDismiss: _dismiss,
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
}

// ─── Celebration Card ───────────────────────────────────────────────

class _CelebrationCard extends StatelessWidget {
  final ResidentTier tier;
  final Map<int, Animation<double>> perkAnimations;
  final VoidCallback onDismiss;

  const _CelebrationCard({
    required this.tier,
    required this.perkAnimations,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perks = _tierPerks[tier] ?? const [];

    return GestureDetector(
      onTap: () {}, // Absorb taps to prevent dismiss when tapping card
      child: Container(
        width: 300,
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: VColors.glassBackground,
          borderRadius: BorderRadius.circular(VRadius.xl),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: VSpacing.lg),
            // Tier icon with pulsing glow
            _PulsingTierIcon(tier: tier),
            const SizedBox(height: VSpacing.md),
            // Congratulations text
            Text(
              'Congratulations!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: VFontWeight.bold,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.xs),
            Text(
              'You\'ve reached ${tier.label}!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: VFontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VSpacing.lg),
            // New perks list
            ...List.generate(perks.length, (i) {
              return _PerkItem(
                perk: perks[i],
                animation: perkAnimations[i],
                index: i,
              );
            }),
            const SizedBox(height: VSpacing.lg),
            // Dismiss button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.lg),
              child: VButton(
                label: 'Awesome!',
                onPressed: onDismiss,
                isFullWidth: true,
              ),
            ),
            const SizedBox(height: VSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ─── Pulsing Tier Icon ──────────────────────────────────────────────

class _PulsingTierIcon extends StatefulWidget {
  final ResidentTier tier;

  const _PulsingTierIcon({required this.tier});

  @override
  State<_PulsingTierIcon> createState() => _PulsingTierIconState();
}

class _PulsingTierIconState extends State<_PulsingTierIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: VColors.gradientBrand,
            boxShadow: [
              BoxShadow(
                color: VColors.primary.withValues(
                  alpha: 0.4 * _pulse.value,
                ),
                blurRadius: 24 * _pulse.value,
                spreadRadius: 4 * _pulse.value,
              ),
            ],
          ),
          child: TierIcon(tier: widget.tier.value, size: 44),
        );
      },
    );
  }
}

// ─── Perk Item ──────────────────────────────────────────────────────

class _PerkItem extends StatelessWidget {
  final String perk;
  final Animation<double>? animation;
  final int index;

  const _PerkItem({
    required this.perk,
    required this.animation,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final anim = animation;
    if (anim == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(20 * (1 - anim.value), 0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VSpacing.lg,
                vertical: VSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VColors.primary.withValues(alpha: anim.value),
                    ),
                  ),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Text(
                      perk,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: anim.value.clamp(0.0, 1.0),
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
}

// ─── Confetti Canvas ────────────────────────────────────────────────

class _ConfettiCanvas extends StatefulWidget {
  final AnimationController controller;

  const _ConfettiCanvas({required this.controller});

  @override
  State<_ConfettiCanvas> createState() => _ConfettiCanvasState();
}

class _ConfettiCanvasState extends State<_ConfettiCanvas> {
  late final List<_ConfettiParticle> _particles;
  final _random = Random(42);

  static const _colors = [
    VColors.achievementEducation,
    VColors.secondary,
    VColors.achievementFinance,
    VColors.tertiary,
    VColors.achievementAdventure,
    VColors.tertiary,
    VColors.primary,
    VColors.primary,
  ];

  @override
  void initState() {
    super.initState();
    _particles = List.generate(60, (i) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 300 + 150;
      return _ConfettiParticle(
        color: _colors[_random.nextInt(_colors.length)],
        startAngle: angle,
        speed: speed,
        size: _random.nextDouble() * 6 + 4,
        delay: _random.nextDouble() * 0.5,
        wobble: _random.nextDouble() * 2 - 1,
      );
    });
    widget.controller.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final t = widget.controller.value;

    return IgnorePointer(
      child: CustomPaint(
        size: screenSize,
        painter: _ConfettiPainter(
          particles: _particles,
          progress: t,
          center: Offset(screenSize.width / 2, screenSize.height / 2.3),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double startAngle;
  final double speed;
  final double size;
  final double delay;
  final double wobble;

  const _ConfettiParticle({
    required this.color,
    required this.startAngle,
    required this.speed,
    required this.size,
    required this.delay,
    required this.wobble,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;
  final Offset center;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.center,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final localT = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (localT <= 0) continue;

      final eased = Curves.easeOutCubic.transform(localT);
      final distance = eased * p.speed * 2;
      final dx =
          center.dx +
          cos(p.startAngle) * distance +
          sin(eased * 8 + p.wobble) * 40;
      final dy =
          center.dy +
          sin(p.startAngle) * distance +
          eased * eased * 120 -
          eased * 80;

      final rotation = eased * p.wobble * pi * 2;
      final opacity = (1.0 - eased).clamp(0.0, 1.0);

      if (opacity <= 0.01) continue;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
