import 'feature_flags.dart';

/// Remote Config segment → Nexus shortcut / bento card order (Wave 17).
class NexusBentoOrder {
  NexusBentoOrder._();

  static const defaultOrder = [
    'season',
    'quest',
    'challenges',
    'league',
    'prestige',
    'trending',
  ];

  static List<String> compactShortcutOrder(List<String> baseOrder) {
    final segment = FeatureFlags.nexusBentoSegment;
    final preferred = switch (segment) {
      'quest_first' => [
        'quest',
        'season',
        'challenges',
        'league',
        'prestige',
        'trending',
      ],
      'social' => [
        'trending',
        'challenges',
        'season',
        'quest',
        'league',
        'prestige',
      ],
      _ => defaultOrder,
    };
    return [
      for (final id in preferred)
        if (baseOrder.contains(id)) id,
      for (final id in baseOrder)
        if (!preferred.contains(id)) id,
    ];
  }
}
