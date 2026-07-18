import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;

import '../services/mutation_outbox_service.dart';
import '../services/storage_service.dart';
import 'achievement_provider.dart';
import 'ally_provider.dart';
import 'channel_provider.dart';
import 'chat_provider.dart';
import 'event_provider.dart';
import 'league_provider.dart';
import 'notification_provider.dart';
import 'post_provider.dart';
import 'quest_provider.dart';
import 'resident_provider.dart';
import 'voice_provider.dart';
import 'world_provider.dart';

/// Removes persisted session artifacts (outbox, caches) after sign-out.
Future<void> clearUserPersistedSessionData() async {
  await MutationOutboxService.clear();
  await StorageService.clearUserSessionData();
}

typedef SessionRead = T Function<T>(ProviderListenable<T> provider);

/// Clears in-memory user state after sign-out so the next session cannot leak data.
///
/// Accepts [Ref.read] or [WidgetRef.read].
void resetUserSessionState(SessionRead read) {
  unawaited(read(voiceProvider.notifier).leaveCampfire());
  read(residentProvider.notifier).clearForSignOut();
  read(worldProvider.notifier).clearForSignOut();
  read(chatProvider.notifier).clearForSignOut();
  read(postProvider.notifier).clearForSignOut();
  read(notificationProvider.notifier).clearForSignOut();
  read(achievementProvider.notifier).clearForSignOut();
  read(leagueProvider.notifier).clearForSignOut();
  read(allyProvider.notifier).clearForSignOut();
  read(channelProvider.notifier).clearForSignOut();
  read(eventProvider.notifier).clearForSignOut();
  read(questProvider.notifier).clearForSignOut();
}

/// Full sign-out cleanup for any auth path (manual sign-out, token expiry, remote revoke).
Future<void> clearSessionOnSignedOut(SessionRead read) async {
  await clearUserPersistedSessionData();
  resetUserSessionState(read);
}
