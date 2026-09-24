import 'package:flutter/foundation.dart';

/// Short OS label for Settings and support tickets.
String get kPlatformBuildLabel {
  if (kIsWeb) return 'Web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => 'iOS',
    TargetPlatform.android => 'Android',
    TargetPlatform.macOS => 'macOS',
    TargetPlatform.windows => 'Windows',
    TargetPlatform.linux => 'Linux',
    TargetPlatform.fuchsia => 'Fuchsia',
  };
}
