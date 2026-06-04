import 'package:flutter/foundation.dart';

import '../models/channel.dart';
import 'world_route_redirects.dart';

/// Central path builders for world explore routes. Prefer these over string
/// interpolation in widgets so encoding and query params stay consistent.
String exploreWorldPath(
  String worldId, {
  String? postId,
  String? highlight,
}) {
  final params = <String, String>{};
  if (postId != null && postId.isNotEmpty) {
    params['post'] = postId;
  }
  if (highlight != null && highlight.isNotEmpty) {
    params['highlight'] = highlight;
  }
  return _path('/explore/${Uri.encodeComponent(worldId)}', params);
}

String exploreDiscoverPath() => '/explore/discover';

/// Channel thread deep link (loads parent message when [extra] is absent).
String threadPath(String messageId) =>
    '/thread/${Uri.encodeComponent(messageId)}';

/// Opens [WorldChannelScreen]. Channel [name] must not be a [kReservedWorldSubRoutes]
/// segment (see docs/vision/world-channel-routing.md).
String worldChannelPath(String worldId, WorldChannel channel) {
  assert(() {
    _warnIfReservedChannelName(channel.name);
    return true;
  }());
  return worldChannelPathFromParts(
    worldId,
    channelName: channel.name,
    channelId: channel.id,
  );
}

String worldChannelDestinationPath(
  String worldId,
  WorldChannel channel, {
  String? worldName,
}) {
  if (channel.channelType == ChannelType.voice) {
    return campfirePath(
      channelId: channel.id,
      name: channel.name,
      worldId: worldId,
      worldName: worldName,
    );
  }
  return worldChannelPath(worldId, channel);
}

@visibleForTesting
String worldChannelPathFromParts(
  String worldId, {
  required String channelName,
  required String channelId,
}) {
  return _path(
    '/explore/${Uri.encodeComponent(worldId)}/${Uri.encodeComponent(channelName)}',
    {'id': channelId},
  );
}

/// @deprecated Use [worldChannelPath]. Kept for existing tests.
String worldChannelExplorePath(String worldId, WorldChannel channel) =>
    worldChannelPath(worldId, channel);

/// @deprecated Use [worldChannelPath].
String worldFeedChatExplorePath(String worldId, WorldChannel channel) =>
    worldChannelPath(worldId, channel);

String worldSettingsPath(String worldId) =>
    '/explore/${Uri.encodeComponent(worldId)}/settings';

String worldMembersPath(
  String worldId, {
  required String worldName,
  required String sovereignId,
}) {
  return _path(
    '/explore/${Uri.encodeComponent(worldId)}/members',
    {
      'name': worldName,
      'sovereign': sovereignId,
    },
  );
}

String worldMarketplacePath(String worldId, {required bool member}) {
  return _path(
    '/explore/${Uri.encodeComponent(worldId)}/marketplace',
    {'member': member ? 'true' : 'false'},
  );
}

String worldPollsPath(
  String worldId, {
  bool admin = false,
  bool create = false,
}) {
  return _path(
    '/explore/${Uri.encodeComponent(worldId)}/polls',
    {
      if (admin) 'admin': 'true',
      if (create) 'create': 'true',
    },
  );
}

String worldTreasuryPath(String worldId, {bool admin = false}) {
  return _path(
    '/explore/${Uri.encodeComponent(worldId)}/treasury',
    admin ? const {'admin': 'true'} : null,
  );
}

String worldChallengesPath(String worldId, {bool admin = false}) {
  return _path(
    '/explore/${Uri.encodeComponent(worldId)}/challenges',
    admin ? const {'admin': 'true'} : null,
  );
}

String worldJobsPath(String worldId, {bool admin = false}) {
  return _path(
    '/explore/${Uri.encodeComponent(worldId)}/jobs',
    admin ? const {'admin': 'true'} : null,
  );
}

String worldArchivePath(String worldId) =>
    '/explore/${Uri.encodeComponent(worldId)}/archive';

String worldManagePath(String worldId) =>
    '/explore/${Uri.encodeComponent(worldId)}/manage';

String worldGovernancePath(String worldId, {String? worldName}) {
  return _path(
    '/explore/${Uri.encodeComponent(worldId)}/governance',
    worldName != null && worldName.isNotEmpty ? {'name': worldName} : null,
  );
}

String residentProfilePath(
  String residentId, {
  String? achievementId,
}) {
  return _path(
    '/residents/${Uri.encodeComponent(residentId)}',
    achievementId != null && achievementId.isNotEmpty
        ? {'achievement': achievementId}
        : null,
  );
}

String leaguesPath() => '/leagues';

/// In-shell chat tab route (keeps bottom navigation).
String chatShellPath(String roomId, {String? draft}) {
  return _path('/chat/${Uri.encodeComponent(roomId)}', draft != null ? {'draft': draft} : null);
}

/// Full-screen DM (outside shell) — profile, marketplace, etc.
String dmPath(String roomId, {String? draft}) {
  return _path('/dm/${Uri.encodeComponent(roomId)}', draft != null ? {'draft': draft} : null);
}

String campfirePath({
  required String channelId,
  String? name,
  String? worldId,
  String? worldName,
}) {
  final params = <String, String>{};
  if (name != null && name.isNotEmpty) {
    params['name'] = name;
  }
  if (worldId != null && worldId.isNotEmpty) {
    params['worldId'] = worldId;
  }
  if (worldName != null && worldName.isNotEmpty) {
    params['worldName'] = worldName;
  }
  return _path('/campfire/${Uri.encodeComponent(channelId)}', params);
}

String auditLogPath(String worldId, {required String worldName}) {
  return _path(
    '/audit-log/${Uri.encodeComponent(worldId)}',
    {'name': worldName},
  );
}

String _path(String base, Map<String, String>? query) {
  if (query == null || query.isEmpty) return base;
  final q = query.entries
      .map(
        (e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
      )
      .join('&');
  return '$base?$q';
}

void _warnIfReservedChannelName(String name) {
  if (kReservedWorldSubRoutes.contains(name)) {
    debugPrint(
      'worldChannelPath: channel name "$name" matches a reserved world '
      'sub-route (${kReservedWorldSubRoutes.join(", ")}). Navigation may '
      'open the wrong screen.',
    );
  }
}
