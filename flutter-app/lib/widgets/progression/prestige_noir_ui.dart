import 'package:flutter/material.dart';

import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/cards/v_prestige_card.dart';

export '../../ui/cards/v_prestige_card.dart' show VPrestigeCard;

/// Uppercase muted section header (Open Design Prestige Noir).
class PrestigeSectionLabel extends StatelessWidget {
  final String label;
  final EdgeInsetsGeometry padding;

  const PrestigeSectionLabel(
    this.label, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(
      VSpacing.lg,
      VSpacing.sm,
      VSpacing.lg,
      VSpacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: VFontSize.labelSm,
          fontWeight: VFontWeight.semiBold,
          letterSpacing: 0.07 * VFontSize.labelSm,
          color: PrestigeNoir.mutedDim,
        ),
      ),
    );
  }
}

/// Gold XP / progress bar — taller track for readable empty fill on noir.
class PrestigeXpBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? fillColor;
  final Gradient? fillGradient;

  const PrestigeXpBar({
    super.key,
    required this.value,
    this.height = 10,
    this.fillColor,
    this.fillGradient,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: PrestigeNoir.borderLight.withValues(alpha: 0.95),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fillGradient == null
                      ? (fillColor ?? VColors.brand)
                      : null,
                  gradient: fillGradient,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Streak hero banner with milestone progress bar.
class PrestigeStreakBanner extends StatelessWidget {
  final int streak;
  final int? nextMilestone;
  final String? subtitle;

  const PrestigeStreakBanner({
    super.key,
    required this.streak,
    this.nextMilestone,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final milestone = nextMilestone;
    final progress = milestone != null && milestone > 0
        ? (streak / milestone).clamp(0.0, 1.0)
        : 1.0;
    final label = subtitle ??
        (milestone != null
            ? 'Day streak · ${milestone - streak} more day${milestone - streak == 1 ? '' : 's'} until reward'
            : 'Day streak');

    return VPrestigeCard(
      padding: const EdgeInsets.all(VSpacing.lg),
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          VColors.warning.withValues(alpha: 0.20),
          PrestigeNoir.surfaceRaised,
        ],
      ),
      borderColor: VColors.warning.withValues(alpha: 0.40),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            size: 36,
            color: streak > 0 ? VColors.warning : PrestigeNoir.mutedDim,
          ),
          const SizedBox(width: VSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: VFontWeight.extraBold,
                    color: VColors.warning,
                    height: 1,
                    letterSpacing: -0.02 * 28,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: VFontSize.labelMd,
                    color: PrestigeNoir.muted,
                  ),
                ),
                const SizedBox(height: VSpacing.sm),
                PrestigeXpBar(
                  value: progress,
                  fillColor: VColors.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented pill tabs in a raised track (Daily / Weekly / hub tabs).
class PrestigeSegmentTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const PrestigeSegmentTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return VPrestigeCard(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _SegmentTab(
                label: labels[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PrestigeNoir.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: VSpacing.sm),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: VFontSize.labelMd,
              fontWeight: VFontWeight.semiBold,
              color: selected ? VColors.brand : PrestigeNoir.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact XP hero for Progress Hub header.
class PrestigeXpHero extends StatelessWidget {
  final int totalXp;
  final double tierProgress;
  final String metaLeft;
  final String? metaRight;

  const PrestigeXpHero({
    super.key,
    required this.totalXp,
    required this.tierProgress,
    required this.metaLeft,
    this.metaRight,
  });

  @override
  Widget build(BuildContext context) {
    return VPrestigeCard(
      padding: const EdgeInsets.all(VSpacing.lg),
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [PrestigeNoir.surfaceRaised, Color(0xFF1A1E24)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TOTAL XP',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                  letterSpacing: 0.07 * VFontSize.labelSm,
                  color: PrestigeNoir.mutedDim,
                ),
              ),
              Text(
                _formatXp(totalXp),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: VFontWeight.extraBold,
                  color: PrestigeNoir.foreground,
                  letterSpacing: -0.02 * 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          PrestigeXpBar(
            value: tierProgress,
            fillGradient: const LinearGradient(
              colors: [VColors.brand, VColors.warning],
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  metaLeft,
                  style: const TextStyle(
                    fontSize: VFontSize.labelMd,
                    color: PrestigeNoir.muted,
                  ),
                ),
              ),
              if (metaRight != null)
                Text(
                  metaRight!,
                  style: const TextStyle(
                    fontSize: VFontSize.labelMd,
                    fontWeight: VFontWeight.semiBold,
                    color: VColors.brand,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatXp(int xp) {
    final chars = xp.toString().split('').reversed.toList();
    final out = <String>[];
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) out.add(',');
      out.add(chars[i]);
    }
    return out.reversed.join();
  }
}

/// Stat tile for 2-column grids.
class PrestigeStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final String? changeLabel;
  final bool changeUp;

  const PrestigeStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.valueColor,
    this.changeLabel,
    this.changeUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return VPrestigeCard(
      padding: const EdgeInsets.all(VSpacing.lg),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: VFontWeight.extraBold,
              color: valueColor,
              letterSpacing: -0.03 * 32,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: VFontSize.labelSm,
              color: PrestigeNoir.mutedDim,
              letterSpacing: 0.05 * VFontSize.labelSm,
            ),
          ),
          if (changeLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              changeLabel!,
              style: TextStyle(
                fontSize: VFontSize.labelSm,
                color: changeUp ? VColors.success : VColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

IconData prestigeQuestIcon(String iconName) {
  return switch (iconName) {
    'create' => Icons.edit_outlined,
    'local_fire_department' => Icons.local_fire_department,
    'chat_bubble' => Icons.chat_bubble_outline,
    'explore' => Icons.explore_outlined,
    _ => Icons.flag_outlined,
  };
}

int? prestigeNextStreakMilestone(int streak) {
  const milestones = [3, 7, 14, 30, 60, 90, 180, 365];
  for (final m in milestones) {
    if (streak < m) return m;
  }
  return null;
}
