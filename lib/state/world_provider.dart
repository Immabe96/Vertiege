import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/tiers.dart';
import '../models/world.dart';
import '../services/supabase.dart';
import '../services/world_service.dart';
import '../services/storage_service.dart';
import '../utils/id_generator.dart';
import 'channel_provider.dart';

class WorldState {
  final Map<String, World> worlds;
  final bool isLoading;

  const WorldState({this.worlds = const {}, this.isLoading = true});

  WorldState copyWith({Map<String, World>? worlds, bool? isLoading}) =>
      WorldState(worlds: worlds ?? this.worlds, isLoading: isLoading ?? this.isLoading);
}

class WorldNotifier extends StateNotifier<WorldState> {
  final Ref _ref;

  WorldNotifier(this._ref) : super(const WorldState());

  Future<void> loadWorlds() async {
    // Merge hardcoded worlds with user-created worlds
    final userWorlds = await _loadUserWorlds();
    final merged = <String, World>{...worldsConfig};

    // Also try loading from Supabase
    if (isSupabaseConfigured()) {
      final remote = await WorldService.loadWorlds();
      for (final data in remote) {
        final id = data['id'] as String?;
        if (id != null && !merged.containsKey(id)) {
          merged[id] = World.fromSupabase(data);
        }
      }
    }

    merged.addAll(userWorlds);
    state = WorldState(worlds: merged, isLoading: false);
  }

  World? getWorld(String worldId) => state.worlds[worldId];

  List<World> get worldsList => state.worlds.values.toList();

  /// Creates a new dominion-type world. Returns the created world's ID.
  Future<String> createWorld({
    required String name,
    required String description,
    required String sovereignId,
    required String sovereignName,
    String icon = 'earth',
  }) async {
    final worldId = generateId();

    // Persist via Supabase
    await WorldService.createWorld(
      name: name,
      type: 'dominion',
      description: description,
      sovereignId: sovereignId,
      sovereignName: sovereignName,
      icon: icon,
    );

    // Create default channels
    final channelNotifier = _ref.read(channelProvider.notifier);
    final channels = await WorldService.createDefaultChannels(worldId);
    if (channels.isNotEmpty) {
      channelNotifier.cacheChannels(worldId, channels);
    }

    // Add to local state
    final newWorld = World(
      id: worldId,
      name: name,
      type: WorldType.dominion,
      description: description,
      sovereignId: sovereignId,
      sovereignName: sovereignName,
      icon: icon,
    );

    state = state.copyWith(
      worlds: {...state.worlds, worldId: newWorld},
    );

    // Persist locally
    await _persistUserWorld(newWorld);

    return worldId;
  }

  void updateWorldSettings({
    required String worldId,
    String? name,
    String? description,
    String? icon,
  }) {
    final world = state.worlds[worldId];
    if (world == null) return;

    final updated = world.copyWith(
      name: name ?? world.name,
      description: description ?? world.description,
      icon: icon ?? world.icon,
    );

    state = state.copyWith(
      worlds: {...state.worlds, worldId: updated},
    );

    // Persist locally
    _persistUserWorld(updated);
  }

  Future<Map<String, World>> _loadUserWorlds() async {
    final raw = await StorageService.getString(StorageService.userWorldsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final list = jsonDecode(raw) as List;
      final result = <String, World>{};
      for (final e in list) {
        final w = World.fromJson(e);
        result[w.id] = w;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> _persistUserWorld(World world) async {
    final worlds = await _loadUserWorlds();
    worlds[world.id] = world;
    final list = worlds.values.map((w) => w.toJson()).toList();
    StorageService.setStringDebounced(
      StorageService.userWorldsKey,
      jsonEncode(list),
    );
  }
}

final worldProvider = StateNotifierProvider<WorldNotifier, WorldState>(
  (ref) => WorldNotifier(ref),
);
