/// Reserved world sub-routes — must not be handled as [WorldChannelScreen] channel names.
const kReservedWorldSubRoutes = <String>{
  'members',
  'settings',
  'marketplace',
  'polls',
  'treasury',
  'challenges',
};

/// When `:channelName` incorrectly matches a reserved segment, redirect to the real screen.
String? redirectReservedWorldSubRoute({
  required String worldId,
  required String segment,
  required String query,
}) {
  if (!kReservedWorldSubRoutes.contains(segment)) return null;
  final q = query.isEmpty ? '' : '?$query';
  return '/explore/$worldId/$segment$q';
}

/// Channel routes require a channel id query param.
String? redirectMissingChannelId({
  required String worldId,
  required String channelName,
  required Map<String, String> queryParams,
}) {
  final id = queryParams['id']?.trim() ?? '';
  if (id.isNotEmpty) return null;
  return '/explore/$worldId';
}
