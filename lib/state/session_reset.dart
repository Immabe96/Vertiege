import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'world_provider.dart';

/// Removes persisted session artifacts (outbox, caches) after sign-out.
Future<void> clearUserPersistedSessionData() async {
  await MutationOutboxService.clear();
  await StorageService.clearUserSessionData();
}

/// Clears in-memory user state after sign-out so the next session cannot leak data.
void resetUserSessionState(WidgetRef ref) {
  ref.read(residentProvider.notifier).clearForSignOut();
  ref.read(worldProvider.notifier).clearForSignOut();
  ref.read(chatProvider.notifier).clearForSignOut();
  ref.read(postProvider.notifier).clearForSignOut();
  ref.read(notificationProvider.notifier).clearForSignOut();
  ref.read(achievementProvider.notifier).clearForSignOut();
  ref.read(leagueProvider.notifier).clearForSignOut();
  ref.read(allyProvider.notifier).clearForSignOut();
  ref.read(channelProvider.notifier).clearForSignOut();
  ref.read(eventProvider.notifier).clearForSignOut();
  ref.read(questProvider.notifier).clearForSignOut();
}
