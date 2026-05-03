import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/world.dart';
import '../../state/world_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/fade_in.dart';
import '../../widgets/core/shimmer.dart';
import '../../widgets/worlds/world_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  WorldType? _selectedType;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value.trim().toLowerCase());
      }
    });
  }

  List<World> _filterWorlds(Iterable<World> allWorlds) {
    return allWorlds.where((world) {
      if (_selectedType != null && world.type != _selectedType) return false;
      if (_searchQuery.isNotEmpty &&
          !world.name.toLowerCase().contains(_searchQuery)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final worldState = ref.watch(worldProvider);
    final allWorlds = worldState.worlds.values.toList();
    final filtered = _filterWorlds(allWorlds);
    final cs = Theme.of(context).colorScheme;
    final isFiltering = _selectedType != null || _searchQuery.isNotEmpty;

    // Top prestige worlds for the featured section
    final featured = List<World>.from(allWorlds)
      ..sort((a, b) => b.prestige.compareTo(a.prestige));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-world'),
        icon: const Icon(Icons.add),
        label: const Text('Create World'),
      ),
      body: worldState.isLoading
          ? _buildLoading()
          : RefreshIndicator(
              onRefresh: () async {
                await ref.read(worldProvider.notifier).loadWorlds();
                await Future<void>.delayed(const Duration(milliseconds: 200));
              },
              child: CustomScrollView(
                slivers: [
                  // Search bar
                  SliverToBoxAdapter(
                    child: FadeIn(
                      delayMs: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Spacing.md, Spacing.sm, Spacing.md, Spacing.xs),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Search worlds...',
                            prefixIcon: const Icon(Icons.search, size: IconSizes.md),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: IconSizes.sm),
                                    tooltip: 'Clear',
                                    onPressed: () {
                                      _debounceTimer?.cancel();
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(RadiusTokens.md),
                            ),
                            filled: true,
                            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Filter chips — Travel App category tabs pattern
                  SliverToBoxAdapter(
                    child: FadeIn(
                      delayMs: 40,
                      child: _buildFilterChips(cs),
                    ),
                  ),

                  // Featured section (only when unfiltered)
                  if (!isFiltering && featured.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: FadeIn(
                        delayMs: 60,
                        child: _SectionHeader(
                          icon: Icons.local_fire_department,
                          title: 'Featured Worlds',
                          color: AppColors.streakOrange,
                          onTap: null,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FadeIn(
                        delayMs: 80,
                        child: _FeaturedRow(worlds: featured.take(5).toList()),
                      ),
                    ),
                  ],

                  // Section header for grid
                  SliverToBoxAdapter(
                    child: FadeIn(
                      delayMs: 100,
                      child: _SectionHeader(
                        icon: isFiltering ? Icons.filter_list : Icons.public,
                        title: isFiltering ? 'Results' : 'All Worlds',
                        color: cs.primary,
                        onTap: null,
                      ),
                    ),
                  ),

                  // Main grid
                  if (filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: FadeIn(
                        delayMs: 120,
                        child: _buildEmpty(cs),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm + 4,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.88,
                          crossAxisSpacing: Spacing.sm,
                          mainAxisSpacing: Spacing.sm,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => WorldCard(
                            world: filtered[index],
                            index: index,
                          ),
                          childCount: filtered.length,
                        ),
                      ),
                    ),

                  // Bottom padding for FAB clearance
                  const SliverToBoxAdapter(
                    child: SizedBox(height: Spacing.xxl + Spacing.lg),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChips(ColorScheme cs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      child: Row(
        children: [
          _FilterPill(
            label: 'All',
            icon: Icons.public,
            selected: _selectedType == null,
            onTap: () => setState(() => _selectedType = null),
          ),
          const SizedBox(width: Spacing.sm),
          _FilterPill(
            label: 'Wealth',
            icon: Icons.diamond,
            selected: _selectedType == WorldType.wealth,
            onTap: () => setState(() => _selectedType = WorldType.wealth),
          ),
          const SizedBox(width: Spacing.sm),
          _FilterPill(
            label: 'Profession',
            icon: Icons.work,
            selected: _selectedType == WorldType.profession,
            onTap: () => setState(() => _selectedType = WorldType.profession),
          ),
          const SizedBox(width: Spacing.sm),
          _FilterPill(
            label: 'Dominion',
            icon: Icons.shield,
            selected: _selectedType == WorldType.dominion,
            onTap: () => setState(() => _selectedType = WorldType.dominion),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchQuery.isNotEmpty ? Icons.search_off : Icons.public_off,
            size: IconSizes.hero,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: Spacing.md),
          Text(
            _searchQuery.isNotEmpty
                ? 'No worlds found for "$_searchQuery"'
                : 'No worlds available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(Spacing.sm + 4, Spacing.sm, Spacing.sm + 4, Spacing.sm),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        crossAxisSpacing: Spacing.sm,
        mainAxisSpacing: Spacing.sm,
      ),
      itemCount: 8,
      itemBuilder: (_, _) => const _ShimmerWorldCard(),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Section Header — adapted from Travel App pattern
// ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm + 4, Spacing.md, Spacing.xs),
      child: Row(
        children: [
          Icon(icon, size: IconSizes.sm + 2, color: color),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              child: Text(
                'View All',
                style: theme.textTheme.labelMedium?.copyWith(color: color),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Filter Pill — custom chip with icon prefix
// ──────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AnimDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(RadiusTokens.round),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.3)
                : cs.outlineVariant.withValues(alpha: AppColors.alphaBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: IconSizes.sm,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: FontSizes.body,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Featured Worlds Horizontal Scroller
// ──────────────────────────────────────────────────────────

class _FeaturedRow extends StatelessWidget {
  final List<World> worlds;

  const _FeaturedRow({required this.worlds});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        itemCount: worlds.length,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.md),
        itemBuilder: (context, index) {
          return SizedBox(
            width: 180,
            child: WorldCard(world: worlds[index], index: index),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Shimmer World Card (skeleton loading)
// ──────────────────────────────────────────────────────────

class _ShimmerWorldCard extends StatelessWidget {
  const _ShimmerWorldCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.15),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Shimmer(height: 80, borderRadius: 0),
          Padding(
            padding: const EdgeInsets.all(Spacing.sm + 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Shimmer(
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: FontSizes.body,
                  borderRadius: RadiusTokens.xs,
                ),
                const SizedBox(height: Spacing.sm),
                Shimmer(
                  width: MediaQuery.of(context).size.width * 0.18,
                  height: FontSizes.caption,
                  borderRadius: RadiusTokens.xs,
                ),
                const SizedBox(height: Spacing.sm),
                const Shimmer(height: FontSizes.caption, borderRadius: RadiusTokens.xs),
                const SizedBox(height: Spacing.xs),
                Shimmer(
                  width: MediaQuery.of(context).size.width * 0.22,
                  height: FontSizes.caption,
                  borderRadius: RadiusTokens.xs,
                ),
                const SizedBox(height: Spacing.sm),
                Row(
                  children: [
                    const Shimmer(width: 50, height: 20, borderRadius: RadiusTokens.xs),
                    const SizedBox(width: Spacing.xs),
                    const Shimmer(width: 36, height: 20, borderRadius: RadiusTokens.xs),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
