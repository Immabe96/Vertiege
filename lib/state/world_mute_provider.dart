import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/world_mute_prefs.dart';

class WorldMuteNotifier extends Notifier<Set<String>> {
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

final worldMuteProvider =
    NotifierProvider<WorldMuteNotifier, Set<String>>(WorldMuteNotifier.new);
