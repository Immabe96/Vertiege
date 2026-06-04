/// Starter charter blurbs when creating a world (Wave 20).
class WorldCharterTemplate {
  final String id;
  final String label;
  final String descriptionSeed;

  const WorldCharterTemplate({
    required this.id,
    required this.label,
    required this.descriptionSeed,
  });
}

const worldCharterTemplates = <WorldCharterTemplate>[
  WorldCharterTemplate(
    id: 'creative',
    label: 'Creative studio',
    descriptionSeed:
        'A world for makers sharing work-in-progress, feedback, and weekly creative challenges. '
        'Respect constructive critique; no unsolicited AI spam.',
  ),
  WorldCharterTemplate(
    id: 'professional',
    label: 'Professional guild',
    descriptionSeed:
        'Career growth, accountability partners, and proof-backed milestones. '
        'Keep discussions professional; verify big claims with evidence.',
  ),
  WorldCharterTemplate(
    id: 'community',
    label: 'Community lounge',
    descriptionSeed:
        'Low-pressure social space for allies, events, and daily check-ins. '
        'Be kind, stay on-topic in channels, and use Campfire when unlocked.',
  ),
  WorldCharterTemplate(
    id: 'competitive',
    label: 'Competitive realm',
    descriptionSeed:
        'Ranked challenges, season goals, and transparent leaderboards. '
        'Play fair — no XP gaming or harassment.',
  ),
];
