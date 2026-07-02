import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/world_mute_prefs.dart';

part 'world_mute_provider.g.dart';

@Riverpod(name: 'worldMuteProvider', keepAlive: true)
class WorldMuteNotifier extends _$WorldMuteNotifier {
  @override
  Set<String> build() {
    Future.microtask(_load);
    return {};
  }

  Future<void> _load() async {
    state = await WorldMutePrefs.load();
  }

  bool isMuted(String worldId) => state.contains(worldId);

  Future<void> toggle(String worldId) async {
    state = await WorldMutePrefs.toggle(worldId);
  }
}
