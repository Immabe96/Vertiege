/// Strategy for resolving data conflicts between local and remote state.
enum ConflictResolution {
  /// Remote state wins. Local changes are discarded.
  remoteWins,

  /// Local state wins. Remote state is overwritten.
  localWins,

  /// Most recent timestamp wins (last-write-wins).
  lastWriteWins,

  /// Merge both states where possible, flag conflicts for user resolution.
  merge,
}
