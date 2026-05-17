import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';
import '../../models/world.dart';
import '../../theme/v_tokens.dart';
import '../core/glass_panel.dart';

class WorldInfoCards extends StatefulWidget {
  final World world;
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
      padding: const EdgeInsets.all(VSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final cards = [
            _InfoStatCard(
              icon: Icons.people_outline,
              value: '${widget.members}',
              label: 'Residents',
              detail: 'View roster',
              color: VColors.primary,
              onTap: widget.onMembersTap,
            ),
            _InfoStatCard(
              icon: Icons.forum_outlined,
              value: '${widget.posts}',
              label: 'Posts',
              detail: 'World feed',
              color: VColors.primary,
            ),
            _InfoStatCard(
              icon: Icons.event_available_outlined,
              value: '${widget.events}',
              label: 'Events',
              detail: widget.events == 0 ? 'None scheduled' : 'Upcoming',
              color: VColors.tertiary,
            ),
            _InfoStatCard(
              icon: Icons.auto_awesome,
              value: '${widget.world.prestige}',
              label: 'Prestige',
              detail: 'World signal',
              color: VColors.tertiary,
            ),
          ];

          return GridView.count(
            crossAxisCount: compact ? 2 : 4,
            crossAxisSpacing: VSpacing.sm,
            mainAxisSpacing: VSpacing.sm,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(VSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: VIconSize.md, color: color),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.chevron_right,
                      size: VIconSize.sm,
                      color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
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
                    fontSize: VFontSize.headlineMd,
                    fontWeight: VFontWeight.bold,
                    color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                  ),
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: VFontSize.labelMd,
                  color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: VFontSize.labelMd,
                  color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
