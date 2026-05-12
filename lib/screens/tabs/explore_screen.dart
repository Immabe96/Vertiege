import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/resident.dart';
import '../../models/world.dart';
import '../../services/access_control.dart';
import '../../services/season_service.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../utils/world_assets.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/core/notification_bell.dart';
import '../../widgets/worlds/world_banner.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  WorldType? _selectedType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<World> _filter(Iterable<World> worlds) {
    final query = _searchQuery.trim().toLowerCase();
    return worlds.where((world) {
      if (_selectedType != null && world.type != _selectedType) return false;
      if (query.isEmpty) return true;
      return world.name.toLowerCase().contains(query) ||
          world.description.toLowerCase().contains(query) ||
          world.sovereignName.toLowerCase().contains(query);
    }).toList();
  }

  List<World> _ranked(List<World> worlds) {
    final ranked = List<World>.from(worlds);
    ranked.sort((a, b) => _discoverScore(b).compareTo(_discoverScore(a)));
    return ranked;
  }

  double _discoverScore(World world) {
    final boost = world.isBoosted ? 120 : 0;
    return world.prestige * 4 +
        world.memberCount * 1.4 +
        world.activityScore * 0.5 +
        boost;
  }

  List<World> _trending(List<World> worlds) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final trending = List<World>.from(worlds);
    trending.sort((a, b) {
      double velocity(World world) {
        final ageDays = ((now - world.createdAt) / 86400000).clamp(0.5, 9999);
        return (world.memberCount * 10 + world.prestige + world.activityScore) /
            ageDays;
      }

      return velocity(b).compareTo(velocity(a));
    });
    return trending;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(worldProvider);
    final resident = ref.watch(residentProvider).resident;
    final worlds = state.worlds.values.toList();
    final rankedWorlds = _ranked(worlds);
    final filtered = _ranked(_filter(worlds));
    final isFiltering = _selectedType != null || _searchQuery.trim().isNotEmpty;
    final spotlight = rankedWorlds.take(5).toList();
    final boosted = rankedWorlds
        .where((world) => world.isBoosted)
        .take(6)
        .toList();
    final trending = _trending(worlds).take(6).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'Discover',
          style: GoogleFonts.spaceGrotesk(
            fontSize: FontSizes.headlineMd,
            fontWeight: FontWeights.bold,
            color: AppColors.ink,
          ),
        ),
        actions: [
          NotificationBell(onPress: () => context.push('/notifications')),
          if ((resident?.tier.value ?? 0) >= 2)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.inkSecondary),
              tooltip: 'Create World',
              onPressed: () => context.push('/create-world'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(worldProvider.notifier).loadWorlds(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _DiscoverHeader(
                controller: _searchController,
                query: _searchQuery,
                worlds: worlds,
                onQueryChanged: (value) => setState(() => _searchQuery = value),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),
            SliverToBoxAdapter(
              child: _WorldTypeStrip(
                selectedType: _selectedType,
                worlds: worlds,
                onSelected: (type) => setState(() => _selectedType = type),
              ),
            ),
            if (!isFiltering && spotlight.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionTitle('Spotlight')),
              SliverToBoxAdapter(
                child: _SpotlightRail(worlds: spotlight, resident: resident),
              ),
            ],
            if (!isFiltering && boosted.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionTitle('Boosted Realms')),
              SliverToBoxAdapter(
                child: _MiniWorldRail(
                  worlds: boosted,
                  resident: resident,
                  badgeLabel: 'Boosted',
                  badgeIcon: Icons.rocket_launch,
                  badgeColor: AppColors.tertiary,
                ),
              ),
            ],
            if (!isFiltering && trending.isNotEmpty) ...[
              const SliverToBoxAdapter(child: _SectionTitle('Trending Now')),
              SliverToBoxAdapter(
                child: _MiniWorldRail(
                  worlds: trending,
                  resident: resident,
                  badgeLabel: 'Active',
                  badgeIcon: Icons.trending_up,
                  badgeColor: AppColors.success,
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: _SectionTitle(
                isFiltering ? 'Matching Worlds' : 'Browse All Worlds',
              ),
            ),
            if (filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.xl),
                  child: AppEmptyState(
                    title: _searchQuery.isNotEmpty
                        ? 'No worlds found'
                        : 'No worlds available',
                    description: _searchQuery.isNotEmpty
                        ? 'No worlds match "$_searchQuery". Try a different search.'
                        : 'No worlds have been created yet.',
                    icon: _searchQuery.isNotEmpty
                        ? Icons.search_off
                        : Icons.public_off,
                    imageAsset: 'assets/generated/empty-worlds.jpg',
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  0,
                  Spacing.md,
                  Spacing.xxl + Spacing.xl,
                ),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Spacing.md),
                  itemBuilder: (context, index) => FadeIn(
                    delayMs: (index * 45).clamp(0, 360),
                    child: _DiscoveryWorldCard(
                      world: filtered[index],
                      resident: resident,
                      compact: index > 2 && !isFiltering,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final List<World> worlds;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  const _DiscoverHeader({
    required this.controller,
    required this.query,
    required this.worlds,
    required this.onQueryChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final featured = List<World>.from(worlds)
      ..sort((a, b) => b.prestige.compareTo(a.prestige));
    final heroWorld = featured.isEmpty ? null : featured.first;
    final memberTotal = worlds.fold<int>(
      0,
      (sum, world) => sum + world.memberCount,
    );
    final season = SeasonService.getCurrentSeason(worlds: worlds);

    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.xs, Spacing.md, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusTokens.full),
        child: SizedBox(
          height: 250,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (heroWorld != null)
                WorldBanner(
                  worldId: heroWorld.id,
                  worldType: heroWorld.type,
                  prestige: heroWorld.prestige,
                  height: 250,
                )
              else
                Container(color: AppColors.surface),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.canvas.withValues(alpha: 0.1),
                      AppColors.canvas.withValues(alpha: 0.72),
                      AppColors.canvas.withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      'Find your next realm',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 34,
                        height: 1.05,
                        fontWeight: FontWeights.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      '${worlds.length} worlds, $memberTotal residents, ${season.name}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    _SearchField(
                      controller: controller,
                      query: query,
                      onQueryChanged: onQueryChanged,
                      onClear: onClear,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onQueryChanged,
      style: const TextStyle(color: AppColors.ink),
      decoration: InputDecoration(
        hintText: 'Search by name, topic, or sovereign',
        hintStyle: const TextStyle(color: AppColors.inkMuted),
        prefixIcon: const Icon(Icons.search, color: AppColors.inkMuted),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: IconSizes.md),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: AppColors.canvas.withValues(alpha: 0.72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          borderSide: const BorderSide(color: AppColors.tertiary),
        ),
        isDense: true,
      ),
    );
  }
}

class _WorldTypeStrip extends StatelessWidget {
  final WorldType? selectedType;
  final List<World> worlds;
  final ValueChanged<WorldType?> onSelected;

  const _WorldTypeStrip({
    required this.selectedType,
    required this.worlds,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final counts = <WorldType, int>{
      for (final type in WorldType.values)
        type: worlds.where((world) => world.type == type).length,
    };

    return SizedBox(
      height: 82,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          Spacing.md,
          Spacing.md,
          Spacing.md,
          Spacing.sm,
        ),
        children: [
          _TypeChip(
            label: 'All',
            count: worlds.length,
            icon: Icons.public,
            selected: selectedType == null,
            color: AppColors.primary,
            onTap: () => onSelected(null),
          ),
          for (final type in WorldType.values) ...[
            const SizedBox(width: Spacing.sm),
            _TypeChip(
              label: _typeLabel(type),
              count: counts[type] ?? 0,
              icon: _typeIcon(type),
              selected: selectedType == type,
              color: _typeColor(type),
              onTap: () => onSelected(type),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimDurations.fast,
        width: 126,
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.16)
              : AppColors.glassBackground,
          borderRadius: BorderRadius.circular(RadiusTokens.xl),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : AppColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: IconSizes.md,
              color: selected ? color : AppColors.inkMuted,
            ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppColors.ink : AppColors.inkSecondary,
                      fontWeight: FontWeights.semiBold,
                    ),
                  ),
                  Text(
                    '$count worlds',
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: FontSizes.labelSm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.lg,
        Spacing.md,
        Spacing.sm,
      ),
      child: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: FontSizes.bodyLg,
          fontWeight: FontWeights.bold,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _SpotlightRail extends StatelessWidget {
  final List<World> worlds;
  final Resident? resident;

  const _SpotlightRail({required this.worlds, required this.resident});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 310,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        itemCount: worlds.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.md),
        itemBuilder: (context, index) => SizedBox(
          width: 292,
          child: _DiscoveryWorldCard(
            world: worlds[index],
            resident: resident,
            spotlight: true,
          ),
        ),
      ),
    );
  }
}

class _MiniWorldRail extends StatelessWidget {
  final List<World> worlds;
  final Resident? resident;
  final String badgeLabel;
  final IconData badgeIcon;
  final Color badgeColor;

  const _MiniWorldRail({
    required this.worlds,
    required this.resident,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        itemCount: worlds.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.md),
        itemBuilder: (context, index) => SizedBox(
          width: 236,
          child: _MiniWorldCard(
            world: worlds[index],
            resident: resident,
            badgeLabel: badgeLabel,
            badgeIcon: badgeIcon,
            badgeColor: badgeColor,
          ),
        ),
      ),
    );
  }
}

class _DiscoveryWorldCard extends StatelessWidget {
  final World world;
  final Resident? resident;
  final bool spotlight;
  final bool compact;

  const _DiscoveryWorldCard({
    required this.world,
    required this.resident,
    this.spotlight = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final locked = resident != null && !canAccessWorld(resident!, world);
    final bannerHeight = spotlight ? 184.0 : (compact ? 116.0 : 158.0);
    final accent = WorldAssets.colorForPrestige(world.prestige);

    return GestureDetector(
      onTap: () => context.push('/explore/${world.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusTokens.full),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: bannerHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'world-icon-${world.id}',
                      child: WorldBanner(
                        worldId: world.id,
                        worldType: world.type,
                        prestige: world.prestige,
                        height: bannerHeight,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.canvas.withValues(alpha: 0.78),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: Spacing.md,
                      right: Spacing.md,
                      bottom: Spacing.md,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              world.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: spotlight
                                    ? FontSizes.headlineMd
                                    : FontSizes.bodyLg,
                                height: 1.08,
                                fontWeight: FontWeights.bold,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          if (locked)
                            const _GlassBadge(
                              label: 'Locked',
                              icon: Icons.lock,
                              color: AppColors.error,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      world.description,
                      maxLines: compact ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Wrap(
                      spacing: Spacing.xs,
                      runSpacing: Spacing.xs,
                      children: [
                        _GlassBadge(
                          label: _typeLabel(world.type),
                          icon: _typeIcon(world.type),
                          color: _typeColor(world.type),
                        ),
                        _GlassBadge(
                          label: '${world.memberCount} residents',
                          icon: Icons.people,
                          color: AppColors.inkSecondary,
                        ),
                        _GlassBadge(
                          label: 'P${world.prestige}',
                          icon: Icons.auto_awesome,
                          color: accent,
                        ),
                        if (world.isBoosted)
                          const _GlassBadge(
                            label: 'Boosted',
                            icon: Icons.rocket_launch,
                            color: AppColors.tertiary,
                          ),
                      ],
                    ),
                    if (!compact || spotlight) ...[
                      const SizedBox(height: Spacing.sm),
                      Text(
                        'Sovereign: ${world.sovereignName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.inkMuted,
                          fontSize: FontSizes.labelSm,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniWorldCard extends StatelessWidget {
  final World world;
  final Resident? resident;
  final String badgeLabel;
  final IconData badgeIcon;
  final Color badgeColor;

  const _MiniWorldCard({
    required this.world,
    required this.resident,
    required this.badgeLabel,
    required this.badgeIcon,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final locked = resident != null && !canAccessWorld(resident!, world);
    return GestureDetector(
      onTap: () => context.push('/explore/${world.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(RadiusTokens.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            WorldBanner(
              worldId: world.id,
              worldType: world.type,
              prestige: world.prestige,
              height: 172,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.canvas.withValues(alpha: 0.04),
                    AppColors.canvas.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _GlassBadge(
                    label: locked ? 'Locked' : badgeLabel,
                    icon: locked ? Icons.lock : badgeIcon,
                    color: locked ? AppColors.error : badgeColor,
                  ),
                  const Spacer(),
                  Text(
                    world.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeights.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '${world.memberCount} residents  P${world.prestige}',
                    style: const TextStyle(
                      color: AppColors.inkSecondary,
                      fontSize: FontSizes.labelSm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _GlassBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvas.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: IconSizes.xs, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: FontSizes.labelSm,
              fontWeight: FontWeights.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

String _typeLabel(WorldType type) {
  return switch (type) {
    WorldType.wealth => 'Wealth',
    WorldType.profession => 'Profession',
    WorldType.dominion => 'Dominion',
  };
}

IconData _typeIcon(WorldType type) {
  return switch (type) {
    WorldType.wealth => Icons.diamond,
    WorldType.profession => Icons.work,
    WorldType.dominion => Icons.shield,
  };
}

Color _typeColor(WorldType type) {
  return switch (type) {
    WorldType.wealth => AppColors.tertiary,
    WorldType.profession => AppColors.primary,
    WorldType.dominion => AppColors.success,
  };
}
