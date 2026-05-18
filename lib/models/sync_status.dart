enum SyncStatus { synced, pending, failed }

extension SyncStatusJson on SyncStatus {
  String get value => name;

  static SyncStatus fromJson(Object? value) {
    return SyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SyncStatus.synced,
    );
  }
}
