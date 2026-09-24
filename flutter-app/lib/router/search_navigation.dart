import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens the global search screen (residents + worlds via [ResidentSearchService]).
void openGlobalSearch(BuildContext context, {String? query}) {
  final trimmed = query?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    context.push(
      '/search?q=${Uri.encodeComponent(trimmed.startsWith('#') ? trimmed.substring(1) : trimmed)}',
    );
    return;
  }
  context.push('/search');
}

/// In-channel message search (filters loaded channel history).
void openChannelSearch(
  BuildContext context, {
  required String worldId,
  required String channelId,
  required String channelName,
  String? query,
}) {
  final params = <String, String>{
    'mode': 'channel',
    'worldId': worldId,
    'channelId': channelId,
    'channelName': channelName,
  };
  if (query != null && query.trim().isNotEmpty) {
    params['q'] = query.trim().startsWith('#')
        ? query.trim().substring(1)
        : query.trim();
  }
  final uri = Uri(path: '/search', queryParameters: params);
  context.push(uri.toString());
}
