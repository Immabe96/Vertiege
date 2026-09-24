import 'package:flutter/material.dart';

import '../theme/v_commune_colors.dart';
import '../widgets/core/status_dot.dart';

/// Normalize [profiles.last_seen_at] (bigint seconds or ms) to epoch ms.
int? parseLastSeenMs(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return _normalizeLastSeenToMs(raw);
  if (raw is num) return _normalizeLastSeenToMs(raw.toInt());
  if (raw is String) {
    final parsed = int.tryParse(raw);
    if (parsed != null) return _normalizeLastSeenToMs(parsed);
    return DateTime.tryParse(raw)?.millisecondsSinceEpoch;
  }
  return null;
}

int _normalizeLastSeenToMs(int raw) {
  // Unix seconds for 2020+ are ~1.5e9; ms are ~1.5e12.
  if (raw < 100000000000) return raw * 1000;
  return raw;
}

Presence presenceFromLastSeenMs(int? lastSeenMs, {DateTime? now}) {
  if (lastSeenMs == null || lastSeenMs == 0) return Presence.offline;
  final clock = now ?? DateTime.now();
  final lastSeen = DateTime.fromMillisecondsSinceEpoch(lastSeenMs);
  final diff = clock.difference(lastSeen).inMinutes;
  if (diff < 3) return Presence.online;
  if (diff < 15) return Presence.idle;
  return Presence.offline;
}

Presence presenceFromProfileField(dynamic lastSeenRaw, {DateTime? now}) {
  return presenceFromLastSeenMs(parseLastSeenMs(lastSeenRaw), now: now);
}

/// Combines persisted [presence_mode] with [last_seen_at] heartbeat.
Presence presenceFromStatusFields({
  String? presenceMode,
  dynamic lastSeenRaw,
  DateTime? now,
}) {
  return switch (presenceMode) {
    'invisible' => Presence.offline,
    'dnd' => Presence.dnd,
    'idle' => Presence.idle,
    'online' => presenceFromProfileField(lastSeenRaw, now: now),
    _ => presenceFromProfileField(lastSeenRaw, now: now),
  };
}

/// Unified status dot colors from [VCommuneColors] (DCX-033).
Color presenceColor(Presence presence) => switch (presence) {
  Presence.online => VCommuneColors.statusOnline,
  Presence.idle => VCommuneColors.statusIdle,
  Presence.dnd => VCommuneColors.statusDnd,
  Presence.offline => VCommuneColors.statusOffline,
};
