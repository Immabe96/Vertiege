import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/chat_density_prefs.dart';

part 'chat_density_provider.g.dart';

@Riverpod(name: 'chatDensityProvider', keepAlive: true)
class ChatDensityNotifier extends _$ChatDensityNotifier {
  @override
  ChatMessageDensity build() {
    Future.microtask(_load);
    return ChatMessageDensity.cozy;
  }

  Future<void> _load() async {
    state = await ChatDensityPrefs.load();
  }

  Future<void> setDensity(ChatMessageDensity density) async {
    state = density;
    await ChatDensityPrefs.save(density);
  }
}
