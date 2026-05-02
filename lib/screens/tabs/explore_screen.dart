import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/world.dart';
import '../../state/world_provider.dart';
import '../../widgets/worlds/world_card.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  WorldType? _selectedType; // null means "All"

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<World> _filterWorlds(Iterable<World> allWorlds) {
    final query = _searchController.text.trim().toLowerCase();
    return allWorlds.where((world) {
      if (_selectedType != null && world.type != _selectedType) return false;
      if (query.isNotEmpty && !world.name.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final worldState = ref.watch(worldProvider);
    final allWorlds = worldState.worlds.values;
    final filtered = _filterWorlds(allWorlds);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Worlds'),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear search',
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
        ],
      ),
      body: worldState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search worlds...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                  ),
                ),

                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedType == null,
                        onSelected: (_) => setState(() => _selectedType = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Wealth'),
                        selected: _selectedType == WorldType.wealth,
                        onSelected: (_) => setState(() => _selectedType = WorldType.wealth),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Profession'),
                        selected: _selectedType == WorldType.profession,
                        onSelected: (_) => setState(() => _selectedType = WorldType.profession),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Dominion'),
                        selected: _selectedType == WorldType.dominion,
                        onSelected: (_) => setState(() => _selectedType = WorldType.dominion),
                      ),
                    ],
                  ),
                ),

                // Content area
                Expanded(
                  child: allWorlds.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.public_off,
                                size: 64,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No worlds available',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No worlds found${_searchController.text.isNotEmpty ? ' for "${_searchController.text}"' : ''}',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(12),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return WorldCard(world: filtered[index]);
                              },
                            ),
                ),
              ],
            ),
    );
  }
}
