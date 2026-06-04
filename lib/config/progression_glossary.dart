import '../models/world.dart';
import 'achievements.dart';
import 'tiers.dart';

/// Canonical names and copy for XP, tier, rep, world prestige, and world level.
///
/// See [docs/vision/gamification-and-worlds.md] — Progression glossary.
enum ProgressionFocus {
  overview,
  xpAndTier,
  repAndStanding,
  worldPrestige,
  worldLevel,
  ascension,
  loungeAccess,
  worldTreasury,
  worldPolls,
}

class ProgressionEntry {
  final ProgressionFocus focus;
  final String title;
  final String oneLiner;
  final String detail;

  const ProgressionEntry({
    required this.focus,
    required this.title,
    required this.oneLiner,
    required this.detail,
  });
}

class ProgressionGlossary {
  ProgressionGlossary._();

  static const sheetTitle = 'How progression works';

  static const String accountIntro =
      'Your account has one global tier (from XP). Each world has its own reputation. '
      'Worlds also have prestige and, for communities you create, a growth level.';

  static const List<ProgressionEntry> entries = [
    ProgressionEntry(
      focus: ProgressionFocus.xpAndTier,
      title: 'XP',
      oneLiner: 'Points from verified achievements and in-app milestones.',
      detail:
          'XP adds up on your profile. It does not replace reputation inside a world — '
          'think of it as your overall résumé in Vertiege.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.xpAndTier,
      title: 'Tier (your rank)',
      oneLiner: 'Global rank: Hustler → High Roller → Elite → Old Money → Apex.',
      detail:
          'Tier is calculated from total XP (500 / 2,000 / 10,000 / 50,000 thresholds). '
          'Higher tier unlocks more worlds, creating worlds, and marketplace selling.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.repAndStanding,
      title: 'Rep (per world)',
      oneLiner: 'Reputation you earn by participating in one world.',
      detail:
          'Rep is tracked separately for each world you join. Posting, trading, and '
          'helping the community raise rep. Leaderboards and council eligibility use rep.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.repAndStanding,
      title: 'Standing (per world)',
      oneLiner: 'Named step from rep: Member, Contributor, Council, and more.',
      detail:
          'Standing is the friendly label for your rep band in that world (e.g. Council at '
          '5,000 rep). It gates features like lounge or treasury management in that realm.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.worldPrestige,
      title: 'World prestige',
      oneLiner: 'How developed a world is (1–50) — unlocks realm features for everyone.',
      detail:
          'World prestige rises with active members, posts, and leader tier. It unlocks '
          'lounge, events, vault, treasury, marketplace, and governance for that world. '
          'This is not your personal tier.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.worldLevel,
      title: 'World growth level',
      oneLiner: 'Levels 1–10 for worlds you create — from activity score.',
      detail:
          'User-created community worlds level up from posts and joins (activity score). '
          'Higher level raises the member cap. Premade worlds use prestige instead.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.ascension,
      title: 'Ascension (optional)',
      oneLiner: 'After Apex, reset XP to earn prestige stars and flair.',
      detail:
          'At max tier with 50,000+ XP you may ascend from the Hall of Ascension: tier '
          'resets to Hustler, XP resets, and you keep prestige stars as endgame flair.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.loungeAccess,
      title: 'Lounge',
      oneLiner: 'A tier-gated voice channel for deeper conversation in a world.',
      detail:
          'Lounges unlock when your global tier and world standing meet the realm rules. '
          'They are optional — join when you want focused discussion, not pressure.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.worldTreasury,
      title: 'Treasury',
      oneLiner: 'Shared world funds for events, grants, and community projects.',
      detail:
          'Members with standing can donate coins; council and sovereign roles manage '
          'payouts. Treasury activity is visible in the audit trail for transparency.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.worldPolls,
      title: 'Polls',
      oneLiner: 'Structured votes on world decisions without spamming the feed.',
      detail:
          'Create polls from the world polls hub when your standing allows. Results '
          'inform governance; they do not replace council votes on binding proposals.',
    ),
  ];

  static List<ProgressionEntry> entriesFor(ProgressionFocus focus) {
    if (focus == ProgressionFocus.overview) return entries;
    return entries.where((e) => e.focus == focus).toList();
  }

  /// UI label for world.prestige (never "Level").
  static String worldPrestigeShort(int prestige) => 'Prestige $prestige';

  static String worldPrestigeFull(int prestige) =>
      'Prestige $prestige/50 · unlocks world features';

  /// UI label for dominion activity level.
  static String worldGrowthLevelShort(int level) => 'Growth level $level';

  static String worldGrowthLevelFull(int level, int maxLevel) =>
      'Growth level $level/$maxLevel · from world activity';

  /// Minimum global tier to enter a wealth world.
  static String worldEntryGateLabel(World world, String resolvedTierOrProfession) {
    if (world.requiredProfession != null) {
      return 'Requires $resolvedTierOrProfession verification';
    }
    final min = world.requiredTier;
    if (min != null && min > 1) {
      final name = tierNames[min] ?? resolvedTierOrProfession;
      return 'Requires $name tier or higher';
    }
    return 'Open to all tiers';
  }

  static String xpToNextTier(int currentXp, int tierValue) {
    if (tierValue >= 5) return '$currentXp XP · Apex tier';
    final next = tierValue + 1;
    final nextThreshold = xpThresholds[next] ?? currentXp;
    final remaining = (nextThreshold - currentXp).clamp(0, 1 << 30);
    final nextName = tierNames[next] ?? 'next tier';
    return '$currentXp XP · $remaining XP to $nextName';
  }
}
