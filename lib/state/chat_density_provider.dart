import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/chat_density_prefs.dart';

class ChatDensityNotifier extends Notifier<ChatMessageDensity> {
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

final chatDensityProvider =
    NotifierProvider<ChatDensityNotifier, ChatMessageDensity>(
      ChatDensityNotifier.new,
    );
