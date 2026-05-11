import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/world.dart';
import '../../services/season_service.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/notification_bell.dart';
import '../../widgets/explore/boosted_worlds_row.dart';
import '../../widgets/explore/featured_worlds_row.dart';
import '../../widgets/explore/section_header.dart';
import '../../widgets/explore/trending_rising_section.dart';
import '../../widgets/shared/filter_pill.dart';
import '../../widgets/worlds/world_card.dart';

enum _ViewMode { grid, tier, list }

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  WorldType? _selectedType;
  _ViewMode _viewMode = _ViewMode.grid;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<World> _filter(Iterable<World> worlds) {
    return worlds.where((w) {
      if (_selectedType != null && w.type != _selectedType) return false;
      if (_searchQuery.isNotEmpty &&
          !w.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  List<World> _sortedByPrestige(List<World> worlds) {
    final sorted = List<World>.from(worlds);
    sorted.sort((a, b) => b.prestige.compareTo(a.prestige));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final allWorlds = ref.watch(worldProvider).worlds.values.toList();
    final filtered = _filter(allWorlds);
    final isFiltering = _selectedType != null || _searchQuery.isNotEmpty;
    final featured = _sortedByPrestige(allWorlds).take(5).toList();
    final boosted = allWorlds.where((w) => w.isBoosted).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(
          'Discovery',
          style: GoogleFonts.spaceGrotesk(
            fontSize: FontSizes.headlineMd,
            fontWeight: FontWeights.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          NotificationBell(onPress: () => context.push('/notifications')),
          Consumer(
            builder: (context, ref, _) {
              final tier = ref.watch(residentProvider).resident?.tier.value ?? 0;
              if (tier < 2) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.add, color: AppColors.inkSecondary),
                tooltip: 'Create World',
                onPressed: () => context.push('/create-world'),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(worldProvider.notifier).loadWorlds();
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.xs),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search worlds...',
                  hintStyle: const TextStyle(color: AppColors.inkMuted),
                  prefixIcon: const Icon(Icons.search, size: IconSizes.md, color: AppColors.inkMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: IconSizes.sm),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.glassBackground,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: 12),
                ),
              ),
            ),

            // Season banner (only when not filtering)
            if (!isFiltering)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                child: _SeasonBannerCard(
                  worlds: allWorlds,
                  onTap: () => context.push('/season'),
                ),
              ),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: Row(
                children: [
                  FilterPill(
                    label: 'All',
                    icon: Icons.public,
                    selected: _selectedType == null,
                    onTap: () => setState(() => _selectedType = null),
                  ),
                  const SizedBox(width: Spacing.sm),
                  FilterPill(
                    label: 'Wealth',
                    icon: Icons.diamond,
                    selected: _selectedType == WorldType.wealth,
                    onTap: () => setState(() => _selectedType = WorldType.wealth),
                  ),
                  const SizedBox(width: Spacing.sm),
                  FilterPill(
                    label: 'Profession',
                    icon: Icons.work,
                    selected: _selectedType == WorldType.profession,
                    onTap: () => setState(() => _selectedType = WorldType.profession),
                  ),
                  const SizedBox(width: Spacing.sm),
                  FilterPill(
                    label: 'Dominion',
                    icon: Icons.shield,
                    selected: _selectedType == WorldType.dominion,
                    onTap: () => setState(() => _selectedType = WorldType.dominion),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.md),

            // Featured worlds row (only when not filtering)
            if (!isFiltering && featured.isNotEmpty) ...[
              const ExploreSectionHeader(title: 'Featured Worlds'),
              SizedBox(
                height: 260,
                child: FeaturedWorldsRow(worlds: featured),
              ),
              const SizedBox(height: Spacing.md),
            ],

            // Boosted realms (only when not filtering and boosted exist)
            if (!isFiltering && boosted.isNotEmpty) ...[
              const ExploreSectionHeader(title: 'Boosted Realms'),
              BoostedWorldsRow(worlds: boosted.take(6).toList()),
              const SizedBox(height: Spacing.md),
            ],

            // Trending & Rising sections (only when not filtering)
            if (!isFiltering)
              ..._buildTrendingRising(allWorlds),

            // View mode toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              child: _buildViewModeToggle(),
            ),

            const SizedBox(height: Spacing.sm),

            // Section header
            ExploreSectionHeader(
              title: isFiltering ? 'Results' : 'All Worlds',
            ),

            const SizedBox(height: Spacing.sm),

            // Content by view mode
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(Spacing.xl),
                child: AppEmptyState(
                  title: _searchQuery.isNotEmpty ? 'No worlds found' : 'No worlds available',
                  description: _searchQuery.isNotEmpty
                      ? 'No worlds match "$_searchQuery". Try a different search.'
                      : 'No worlds have been created yet.',
                  icon: _searchQuery.isNotEmpty ? Icons.search_off : Icons.public_off,
                ),
              )
            else if (_viewMode == _ViewMode.grid)
              _buildGrid(filtered)
            else if (_viewMode == _ViewMode.tier)
              _buildTierView(filtered)
            else
              _buildListView(filtered),

            const SizedBox(height: Spacing.xxl + Spacing.xl),
          ],
        ),
      ),
    );
  }

  // ── View mode toggle ──────────────────────────────────────

  Widget _buildViewModeToggle() {
    return Container(
      padding: const EdgeInsets.all(Spacing.xs),
      decoration: BoxDecoration(
        color: AppColors.glassBackground,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          _ToggleBtn(
            icon: Icons.grid_view_rounded,
            label: 'Grid',
            selected: _viewMode == _ViewMode.grid,
            onTap: () => setState(() => _viewMode = _ViewMode.grid),
          ),
          _ToggleBtn(
            icon: Icons.stacked_bar_chart,
            label: 'Tier',
            selected: _viewMode == _ViewMode.tier,
            onTap: () => setState(() => _viewMode = _ViewMode.tier),
          ),
          _ToggleBtn(
            icon: Icons.view_list_rounded,
            label: 'List',
            selected: _viewMode == _ViewMode.list,
            onTap: () => setState(() => _viewMode = _ViewMode.list),
          ),
        ],
      ),
    );
  }

  // ── Grid view ─────────────────────────────────────────────

  Widget _buildGrid(List<World> worlds) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.xxl),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Spacing.sm + 4,
        crossAxisSpacing: Spacing.sm + 4,
        childAspectRatio: 0.72,
      ),
      itemCount: worlds.length,
      itemBuilder: (_, i) => WorldCard(world: worlds[i], index: i, wide: false),
    );
  }

  // ── Tier view ─────────────────────────────────────────────

  Widget _buildTierView(List<World> worlds) {
    final apex = worlds.where((w) => w.prestige >= 40).toList();
    final elite = worlds.where((w) => w.prestige >= 20 && w.prestige < 40).toList();
    final hustler = worlds.where((w) => w.prestige < 20).toList();

    final sections = [
      if (apex.isNotEmpty) ('Apex', AppColors.tertiary, apex),
      if (elite.isNotEmpty) ('Elite', AppColors.primary, elite),
      if (hustler.isNotEmpty) ('Hustler', AppColors.hustler, hustler),
    ];

    return Column(
      children: sections.map((s) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 3, height: 20,
                      decoration: BoxDecoration(
                        color: s.$2, borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      s.$1,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: FontSizes.headlineLg,
                        fontWeight: FontWeights.semiBold,
                        color: s.$2,
                      ),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.xxl),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: Spacing.sm + 4,
                  crossAxisSpacing: Spacing.sm + 4,
                  childAspectRatio: 0.72,
                ),
                itemCount: s.$3.length,
                itemBuilder: (_, i) => WorldCard(world: s.$3[i], index: i, wide: false),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── List view ─────────────────────────────────────────────

  Widget _buildListView(List<World> worlds) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Column(
        children: worlds.asMap().entries.map((e) {
          return Padding(
            padding: EdgeInsets.only(bottom: e.key < worlds.length - 1 ? Spacing.sm + 4 : 0),
            child: WorldCard(world: e.value, index: e.key, wide: true),
          );
        }).toList(),
      ),
    );
  }

  // ── Trending & Rising ─────────────────────────────────────

  List<Widget> _buildTrendingRising(List<World> allWorlds) {
    final now = DateTime.now();
    final scored = allWorlds.map((w) {
      final ageDays = ((now.millisecondsSinceEpoch - w.createdAt) / 86400000).clamp(0.5, 9999);
      final velocity = (w.memberCount * 10 + w.prestige) / ageDays;
      return (world: w, velocity: velocity);
    }).toList();

    final trending = List<({World world, double velocity})>.from(scored)
      ..sort((a, b) => b.velocity.compareTo(a.velocity));
    final topTrending = trending.take(3).toList();

    final rising = scored.where((s) {
      final age = ((now.millisecondsSinceEpoch - s.world.createdAt) / 86400000);
      return age < 30;
    }).toList()
      ..sort((a, b) => b.velocity.compareTo(a.velocity));
    final topRising = rising.take(3).toList();

    return [
      if (topTrending.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.xs),
          child: TrendingRisingSection(
            title: 'Trending',
            worlds: topTrending.map((s) => s.world).toList(),
            badgeLabel: 'HOT',
            badgeColor: AppColors.semanticError,
          ),
        ),
      if (topRising.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.md),
          child: TrendingRisingSection(
            title: 'Rising',
            worlds: topRising.map((s) => s.world).toList(),
            badgeLabel: 'NEW',
            badgeColor: AppColors.semanticSuccess,
          ),
        ),
    ];
  }
}

// ── View mode toggle button ──────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: Spacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(RadiusTokens.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: IconSizes.sm, color: selected ? AppColors.primary : AppColors.inkMuted),
              const SizedBox(width: Spacing.xs),
              Text(label, style: TextStyle(
                fontSize: FontSizes.labelSm,
                fontWeight: selected ? FontWeights.semiBold : FontWeights.regular,
                color: selected ? AppColors.primary : AppColors.inkMuted,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Season banner card ───────────────────────────────────────

class _SeasonBannerCard extends StatelessWidget {
  final List<World> worlds;
  final VoidCallback onTap;

  const _SeasonBannerCard({required this.worlds, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final season = SeasonService.getCurrentSeason(worlds: worlds);
    final subtitle = SeasonService.bannerSubtitle(season.scores);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.lg),
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(RadiusTokens.card),
          border: Border.all(
            color: AppColors.tertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 3, height: 56,
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(season.name.toUpperCase(), style: GoogleFonts.spaceGrotesk(
                    fontSize: FontSizes.bodyMd, fontWeight: FontWeights.bold, color: AppColors.tertiary,
                  )),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: FontSizes.labelSm, color: AppColors.inkSecondary)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
              decoration: BoxDecoration(
                color: AppColors.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
              ),
              child: const Text('VIEW', style: TextStyle(
                fontSize: FontSizes.labelSm, fontWeight: FontWeights.bold, color: AppColors.tertiary,
              )),
            ),
          ],
        ),
      ),
    );
  }
}
