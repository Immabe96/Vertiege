import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

/// Secondary navigation hub — accessible via the More tab.
///
/// Collects settings, shop, achievements, and other secondary screens
/// that don't need dedicated bottom nav slots.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor:
            (isDark ? VColors.surfaceDark : VColors.surface).withValues(alpha: 0.86),
        elevation: 0,
        title: Text(
          'More',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(VSpacing.md),
        children: [
          _MoreSection(
            title: 'Your Journey',
            isDark: isDark,
            items: [
              _MoreItem(
                icon: Icons.emoji_events,
                label: 'Achievements',
                onTap: () => context.push('/achievements'),
              ),
              _MoreItem(
                icon: Icons.trending_up,
                label: 'Ascension Path',
                onTap: () => context.push('/ascension-path'),
              ),
              _MoreItem(
                icon: Icons.leaderboard,
                label: 'Hall of Ascension',
                onTap: () => context.push('/hall-of-ascension'),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          _MoreSection(
            title: 'Account',
            isDark: isDark,
            items: [
              _MoreItem(
                icon: Icons.shopping_bag,
                label: 'Cosmetics Shop',
                onTap: () => context.push('/shop'),
              ),
              _MoreItem(
                icon: Icons.workspace_premium,
                label: 'Subscription',
                onTap: () => context.push('/subscription'),
              ),
              _MoreItem(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () => context.push('/settings'),
              ),
              _MoreItem(
                icon: Icons.notifications,
                label: 'Notifications',
                onTap: () => context.push('/notifications'),
              ),
            ],
          ),
          const SizedBox(height: VSpacing.md),
          _MoreSection(
            title: 'Explore',
            isDark: isDark,
            items: [
              _MoreItem(
                icon: Icons.public,
                label: 'Discover Worlds',
                onTap: () => context.push('/explore'),
              ),
              _MoreItem(
                icon: Icons.search,
                label: 'Search',
                onTap: () => context.push('/search'),
              ),
              _MoreItem(
                icon: Icons.emoji_events,
                label: 'Challenges',
                onTap: () => context.push('/challenges'),
              ),
              _MoreItem(
                icon: Icons.groups,
                label: 'Leagues',
                onTap: () => context.push('/leagues'),
              ),
              _MoreItem(
                icon: Icons.calendar_month,
                label: 'Season',
                onTap: () => context.push('/season'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoreSection extends StatelessWidget {
  final String title;
  final bool isDark;
  final List<_MoreItem> items;

  const _MoreSection({
    required this.title,
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            fontWeight: VFontWeight.semiBold,
            color: isDark
                ? VColors.onSurfaceVariantDark
                : VColors.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: VSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? VColors.surfaceContainerDark
                : VColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(VRadius.lg),
            border: Border.all(
              color: isDark
                  ? VColors.outlineVariantDark
                  : VColors.outlineVariant,
            ),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icon,
        size: VIconSize.md,
        color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: VFontSize.bodyMd,
          color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: VIconSize.sm),
      onTap: onTap,
      dense: true,
    );
  }
}
