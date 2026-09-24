enum ChannelMuteMode {
  off,
  mentionsOnly,
  all;

  String get storageValue => switch (this) {
    ChannelMuteMode.off => 'off',
    ChannelMuteMode.mentionsOnly => 'mentions_only',
    ChannelMuteMode.all => 'all',
  };

  static ChannelMuteMode fromStorage(String? raw) {
    return switch (raw) {
      'mentions_only' => ChannelMuteMode.mentionsOnly,
      'all' => ChannelMuteMode.all,
      _ => ChannelMuteMode.off,
    };
  }

  String get label => switch (this) {
    ChannelMuteMode.off => 'All notifications',
    ChannelMuteMode.mentionsOnly => 'Mentions only',
    ChannelMuteMode.all => 'Muted',
  };
}
