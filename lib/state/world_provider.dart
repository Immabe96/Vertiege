import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/tiers.dart';
import '../models/world.dart';

class WorldState {
  final Map<String, World> worlds;
  final bool isLoading;

  const WorldState({this.worlds = const {}, this.isLoading = true});

  WorldState copyWith({Map<String, World>? worlds, bool? isLoading}) =>
      WorldState(worlds: worlds ?? this.worlds, isLoading: isLoading ?? this.isLoading);
}

class WorldNotifier extends StateNotifier<WorldState> {
  WorldNotifier() : super(const WorldState());

  Future<void> loadWorlds() async {
    state = WorldState(worlds: worldsConfig, isLoading: false);
  }

  World? getWorld(String worldId) => state.worlds[worldId];

  List<World> get worldsList => state.worlds.values.toList();
}

final worldProvider = StateNotifierProvider<WorldNotifier, WorldState>(
  (ref) => WorldNotifier(),
);
