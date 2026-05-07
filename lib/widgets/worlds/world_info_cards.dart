import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../core/glass_panel.dart';

class WorldInfoCards extends StatefulWidget {
  final dynamic world;
  final int members;
  final int posts;
  final int events;
  final VoidCallback onVisible;
  final VoidCallback onMembersTap;

  const WorldInfoCards({
    super.key,
    required this.world,
    required this.members,
    required this.posts,
    required this.events,
    required this.onVisible,
    required this.onMembersTap,
  });

  @override
  State<WorldInfoCards> createState() => _WorldInfoCardsState();
}

class _WorldInfoCardsState extends State<WorldInfoCards> {
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_triggered && mounted) {
        _triggered = true;
        widget.onVisible();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        children: [
          // Row 1: Members + Posts
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: widget.onMembersTap,
                  child: GlassPanel(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.people,
                            size: IconSizes.lg, color: AppColors.primary),
                        const SizedBox(height: Spacing.sm),
                        Text(
                          '${widget.members}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: FontSizes.headlineLg,
                            fontWeight: FontWeights.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Members',
                          style: TextStyle(
                            fontSize: FontSizes.labelSm,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: GlassPanel(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.forum,
                          size: IconSizes.lg, color: AppColors.primary),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        '${widget.posts}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: FontSizes.headlineLg,
                          fontWeight: FontWeights.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Posts',
                        style: TextStyle(
                          fontSize: FontSizes.labelSm,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          // Row 2: Events + Prestige / Sovereign
          Row(
            children: [
              Expanded(
                child: GlassPanel(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.trending_up,
                          size: IconSizes.lg, color: AppColors.tertiary),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        '${widget.events}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: FontSizes.headlineLg,
                          fontWeight: FontWeights.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Events',
                        style: TextStyle(
                          fontSize: FontSizes.labelSm,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: GlassPanel(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: IconSizes.lg, color: AppColors.tertiary),
                      const SizedBox(height: Spacing.sm),
                      Text(
                        '${widget.world.prestige}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: FontSizes.headlineLg,
                          fontWeight: FontWeights.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Prestige',
                        style: TextStyle(
                          fontSize: FontSizes.labelSm,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
