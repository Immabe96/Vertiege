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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final cards = [
            _InfoStatCard(
              icon: Icons.people_outline,
              value: '${widget.members}',
              label: 'Residents',
              detail: 'View roster',
              color: AppColors.primary,
              onTap: widget.onMembersTap,
            ),
            _InfoStatCard(
              icon: Icons.forum_outlined,
              value: '${widget.posts}',
              label: 'Posts',
              detail: 'World feed',
              color: AppColors.primary,
            ),
            _InfoStatCard(
              icon: Icons.event_available_outlined,
              value: '${widget.events}',
              label: 'Events',
              detail: widget.events == 0 ? 'None scheduled' : 'Upcoming',
              color: AppColors.tertiary,
            ),
            _InfoStatCard(
              icon: Icons.auto_awesome,
              value: '${widget.world.prestige}',
              label: 'Prestige',
              detail: 'World signal',
              color: AppColors.tertiary,
            ),
          ];

          return GridView.count(
            crossAxisCount: compact ? 2 : 4,
            crossAxisSpacing: Spacing.sm,
            mainAxisSpacing: Spacing.sm,
            childAspectRatio: compact ? 1.42 : 1.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cards,
          );
        },
      ),
    );
  }
}

class _InfoStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String detail;
  final Color color;
  final VoidCallback? onTap;

  const _InfoStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.detail,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: IconSizes.md, color: color),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(
                      Icons.chevron_right,
                      size: IconSizes.sm,
                      color: AppColors.inkMuted,
                    ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: FontSizes.headlineMd,
                    fontWeight: FontWeights.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: FontSizes.labelSm,
                  color: AppColors.inkSecondary,
                  fontWeight: FontWeights.semiBold,
                ),
              ),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: FontSizes.labelSm,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
