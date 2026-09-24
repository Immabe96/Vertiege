/// Connectivity and sync state for the outbox and repository layer.
enum SyncStatus {
  /// Online, outbox empty, last sync succeeded.
  synced,

  /// Online, outbox has pending mutations being replayed.
  syncing,

  /// Online, some mutations failed and are awaiting retry.
  pending,

  /// Offline — mutations are being queued locally.
  offline,

  /// Online, but the last sync attempt failed with a non-retryable error.
  error,
}

extension SyncStatusExtension on SyncStatus {
  bool get isOnline => this != SyncStatus.offline;
  bool get hasIssues =>
      this == SyncStatus.pending || this == SyncStatus.error;
}

extension SyncStatusJson on SyncStatus {
  String get value => name;

  static SyncStatus fromJson(Object? value) {
    return SyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SyncStatus.synced,
    );
  }
}
