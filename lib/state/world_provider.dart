import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/tiers.dart';
import '../models/world.dart';
import '../models/post.dart';
import '../models/alliance.dart';
import '../services/world_service.dart';
import '../services/storage_service.dart';
import '../services/council_service.dart';
import '../services/prestige_service.dart';
import '../services/store_service.dart';
import '../utils/id_generator.dart';
import 'channel_provider.dart';

class WorldState {
  final Map<String, World> worlds;
  final bool isLoading;
  final List<Alliance> alliances;

  const WorldState({
    this.worlds = const {},
    this.isLoading = true,
    this.alliances = const [],
  });

  WorldState copyWith({
    Map<String, World>? worlds,
    bool? isLoading,
    List<Alliance>? alliances,
  }) => WorldState(
    worlds: worlds ?? this.worlds,
    isLoading: isLoading ?? this.isLoading,
    alliances: alliances ?? this.alliances,
  );
}

class WorldNotifier extends Notifier<WorldState> {
  @override
  WorldState build() {
    // Load local config worlds immediately — no network needed
    return const WorldState(isLoading: true);
  }

  static const String _worldsCacheKey = '@worlds_cache';

  Future<void> loadWorlds() async {
    state = state.copyWith(isLoading: true);
    try {
      final remote = await WorldService.loadWorlds().timeout(
        const Duration(seconds: 8),
      );
      final worlds = <String, World>{};
      for (final data in remote) {
        final world = World.fromSupabase(data);
        if (world.id.isNotEmpty) worlds[world.id] = world;
      }
      state = state.copyWith(worlds: worlds, isLoading: false);
      await _cacheWorlds(worlds);
    } catch (_) {
      final cached = await _loadCachedWorlds();
      state = state.copyWith(worlds: cached ?? const {}, isLoading: false);
    }

    try {
      await _loadAlliances().timeout(const Duration(seconds: 3));
    } catch (_) {}
    state = state.copyWith(alliances: state.alliances);
  }

  World? getWorld(String worldId) => state.worlds[worldId];

  World? getWorldBySlug(String slug) {
    for (final world in state.worlds.values) {
      if (world.slug == slug) return world;
    }
    return null;
  }

  List<World> get worldsList {
    final worlds = state.worlds.values.toList()
      ..sort((a, b) {
        final bySort = a.sortOrder.compareTo(b.sortOrder);
        return bySort != 0 ? bySort : a.name.compareTo(b.name);
      });
    return worlds;
  }

  Future<String> createWorld({
    required String name,
    required String description,
    required String sovereignId,
    required String sovereignName,
    String icon = 'earth',
    String? dominionType,
    String? worldCurrencyName,
    List<String>? tags,
  }) async {
    final worldData = await WorldService.createWorld(
      name: name,
      type: 'dominion',
      description: description,
      sovereignId: sovereignId,
      sovereignName: sovereignName,
      icon: icon,
      dominionType: dominionType,
      worldCurrencyName: worldCurrencyName,
      tags: tags,
    );

    final worldId = worldData?['id'] as String? ?? generateId();

    final channelNotifier = ref.read(channelProvider.notifier);
    final channels = await WorldService.createDefaultChannels(worldId);
    if (channels.isNotEmpty) {
      channelNotifier.cacheChannels(worldId, channels);
    }

    final newWorld = World(
      id: worldId,
      slug: worldData?['slug'] as String? ?? '',
      name: name,
      type: WorldType.dominion,
      description: description,
      sovereignId: sovereignId,
      sovereignName: sovereignName,
      icon: icon,
      dominionType: dominionType != null
          ? DominionType.values.firstWhere(
              (t) => t.name == dominionType,
              orElse: () => DominionType.sanctuary,
            )
          : null,
      worldCurrencyName: worldCurrencyName ?? 'Coins',
      tags: tags ?? [],
    );

    state = state.copyWith(worlds: {...state.worlds, worldId: newWorld});

    return worldId;
  }

  Future<void> updateWorldSettings({
    required String worldId,
    String? name,
    String? description,
    String? icon,
  }) async {
    final world = state.worlds[worldId];
    if (world == null) return;

    final updated = world.copyWith(
      name: name ?? world.name,
      description: description ?? world.description,
      icon: icon ?? world.icon,
    );

    state = state.copyWith(worlds: {...state.worlds, worldId: updated});

    await WorldService.updateWorld(
      worldId: worldId,
      name: name,
      description: description,
      icon: icon,
    );
  }

  Future<int> updateWorldPrestige({
    required String worldId,
    required int memberCount,
    required Map<String, int> memberTiers,
    required List<Post> recentPosts,
  }) async {
    final world = state.worlds[worldId];
    if (world == null) return 0;

    final sovereignTier = PrestigeService.resolveSovereignTier(
      world.sovereignId,
      memberTiers,
      world,
    );
    final avgTier = PrestigeService.computeAvgTier(memberTiers);

    final newPrestige = await PrestigeService.recalculateForWorld(
      worldId: worldId,
      world: world,
      memberCount: memberCount,
      avgMemberTier: avgTier,
      sovereignTier: sovereignTier,
      recentPosts: recentPosts,
    );

    if (newPrestige != world.prestige) {
      final updated = world.copyWith(prestige: newPrestige);
      state = state.copyWith(worlds: {...state.worlds, worldId: updated});
    }

    return newPrestige;
  }

  WorldFeatures featuresForWorld(String worldId) {
    final world = state.worlds[worldId];
    if (world == null) return const WorldFeatures();
    final fn = getWorldFeatures;
    return fn(world.prestige, world.type);
  }

  void addActivityScore(String worldId, int points) {
    final world = state.worlds[worldId];
    if (world == null || world.type != WorldType.dominion) return;

    final updated = world.copyWith(activityScore: world.activityScore + points);
    state = state.copyWith(worlds: {...state.worlds, worldId: updated});
  }

  int worldLevelFor(String worldId) {
    final world = state.worlds[worldId];
    if (world == null) return 1;
    if (world.type != WorldType.dominion) return 10;
    return getWorldLevel(world.activityScore);
  }

  int residentCapacityFor(String worldId) {
    final world = state.worlds[worldId];
    if (world == null) return 20;
    if (world.type != WorldType.dominion) return 9999;
    return getResidentCapacity(worldLevelFor(worldId));
  }

  void incrementMemberCount(String worldId) {
    final world = state.worlds[worldId];
    if (world == null) return;
    final updated = world.copyWith(memberCount: world.memberCount + 1);
    state = state.copyWith(worlds: {...state.worlds, worldId: updated});
  }

  void decrementMemberCount(String worldId) {
    final world = state.worlds[worldId];
    if (world == null) return;
    final updated = world.copyWith(
      memberCount: (world.memberCount - 1).clamp(0, 99999),
    );
    state = state.copyWith(worlds: {...state.worlds, worldId: updated});
  }

  Future<List<CouncilAction>> runCouncilCheck(String worldId) async {
    final actions = await CouncilService.checkWorld(worldId);

    for (final action in actions) {
      if (action.type == 'elect' && action.residentId != null) {
        final world = state.worlds[worldId];
        if (world != null) {
          final updated = world.copyWith(
            sovereignId: action.residentId,
            sovereignName: action.residentName ?? world.sovereignName,
          );
          state = state.copyWith(worlds: {...state.worlds, worldId: updated});
        }
      }
    }

    return actions;
  }

  Future<StorePurchaseState> boostWorld(String worldId) async {
    final world = state.worlds[worldId];
    if (world == null || world.type != WorldType.dominion) {
      return StorePurchaseState.error;
    }
    if (world.boostsRemaining <= 0) return StorePurchaseState.error;

    final result = await StoreService.buyWorldBoost();
    if (result != StorePurchaseState.purchased) return result;

    final now = DateTime.now();
    final thisMonth = now.year * 12 + now.month;
    final newCount = world.lastBoostMonth == thisMonth
        ? world.boostCount + 1
        : 1;

    final updated = world.copyWith(
      activityScore: world.activityScore + World.boostActivityPoints,
      boostCount: newCount,
      lastBoostMonth: thisMonth,
    );
    state = state.copyWith(worlds: {...state.worlds, worldId: updated});

    return StorePurchaseState.purchased;
  }

  void formAlliance(String worldId1, String worldId2) {
    final w1 = state.worlds[worldId1];
    final w2 = state.worlds[worldId2];
    if (w1 == null || w2 == null) return;
    final exists = state.alliances.any(
      (a) =>
          (a.worldId1 == worldId1 && a.worldId2 == worldId2) ||
          (a.worldId1 == worldId2 && a.worldId2 == worldId1),
    );
    if (exists) return;

    final alliance = Alliance(
      id: 'ally_${generateId()}',
      worldId1: worldId1,
      worldId2: worldId2,
      worldName1: w1.name,
      worldName2: w2.name,
      formedAt: DateTime.now(),
    );
    state = state.copyWith(alliances: [...state.alliances, alliance]);
    _persistAlliances();
  }

  List<Alliance> alliancesForWorld(String worldId) {
    return state.alliances
        .where((a) => a.worldId1 == worldId || a.worldId2 == worldId)
        .toList();
  }

  Future<void> _loadAlliances() async {
    final raw = await StorageService.getString('@alliances_data');
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      final alliances = list
          .map((e) => Alliance.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(alliances: alliances);
    } catch (_) {}
  }

  void _persistAlliances() {
    final list = state.alliances.map((a) => a.toJson()).toList();
    StorageService.setStringDebounced('@alliances_data', jsonEncode(list));
  }

  Future<void> _cacheWorlds(Map<String, World> worlds) async {
    try {
      final json = jsonEncode(
        worlds.values.map((w) {
          final data = <String, dynamic>{
            'id': w.id,
            'slug': w.slug,
            'name': w.name,
            'type': w.type.name,
            'description': w.description,
            'sovereignId': w.sovereignId,
            'sovereignName': w.sovereignName,
            'prestige': w.prestige,
            'icon': w.icon,
            'memberCount': w.memberCount,
            'activityScore': w.activityScore,
            'sortOrder': w.sortOrder,
            'createdAt': w.createdAt,
          };
          if (w.constitution.admission != 'open') {
            data['admission'] = w.constitution.admission;
          }
          if (w.constitution.requiredProfession != null) {
            data['requiredProfession'] = w.constitution.requiredProfession;
          }
          if (w.constitution.minTier != null) {
            data['minTier'] = w.constitution.minTier;
          }
          if (w.constitution.entryFee > 0) {
            data['entryFee'] = w.constitution.entryFee;
          }
          return data;
        }).toList(),
      );
      await StorageService.setString(_worldsCacheKey, json);
    } catch (_) {}
  }

  Future<Map<String, World>?> _loadCachedWorlds() async {
    try {
      final raw = await StorageService.getString(_worldsCacheKey);
      if (raw == null || raw.isEmpty) return null;
      final list = jsonDecode(raw) as List;
      final worlds = <String, World>{};
      for (final item in list) {
        final data = item as Map<String, dynamic>;
        final world = World(
          id: data['id'] as String,
          slug: data['slug'] as String? ?? '',
          name: data['name'] as String? ?? '',
          type: WorldType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => WorldType.dominion,
          ),
          description: data['description'] as String? ?? '',
          sovereignId: data['sovereignId'] as String? ?? '',
          sovereignName: data['sovereignName'] as String? ?? '',
          prestige: data['prestige'] as int? ?? 1,
          icon: data['icon'] as String? ?? 'earth',
          memberCount: data['memberCount'] as int? ?? 0,
          activityScore: data['activityScore'] as int? ?? 0,
          sortOrder: data['sortOrder'] as int? ?? 0,
          createdAt: data['createdAt'] as int? ?? 0,
        );
        if (world.id.isNotEmpty) worlds[world.id] = world;
      }
      return worlds;
    } catch (_) {
      return null;
    }
  }
}

final worldProvider = NotifierProvider<WorldNotifier, WorldState>(
  WorldNotifier.new,
);
