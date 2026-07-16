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

  /// Closed-beta intro — Tier, XP, Streak only.
  static const String accountIntro =
      'Earn XP from verified achievements and daily check-ins. '
      'XP raises your global tier. Keep a streak for bonus XP. '
      'World reputation and advanced prestige unlock later.';

  static const List<ProgressionEntry> entries = [
    ProgressionEntry(
      focus: ProgressionFocus.xpAndTier,
      title: 'XP',
      oneLiner: 'Points from verified achievements and daily activity.',
      detail:
          'XP adds up on your profile. Submit proof, get verified, show up '
          'on Nexus — that is the main way to grow.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.xpAndTier,
      title: 'Tier',
      oneLiner: 'Your global rank from XP: Hustler → High Roller → Elite → …',
      detail:
          'Tier unlocks more worlds and capabilities. Thresholds are at '
          '500 / 2,000 / 10,000 / 50,000 XP.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.xpAndTier,
      title: 'Streak',
      oneLiner: 'Check in daily for bonus XP and milestone rewards.',
      detail:
          'Open Quests or Progress each day to keep your streak. Miss a day '
          'and it resets unless you have a streak shield.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.repAndStanding,
      title: 'Rep (per world)',
      oneLiner: 'Reputation you earn by participating in one world.',
      detail:
          'Rep is tracked separately for each world you join. Posting and '
          'helping raise rep. Advanced features use rep bands later.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.repAndStanding,
      title: 'Standing (per world)',
      oneLiner: 'Named step from rep: Member, Contributor, Council, and more.',
      detail:
          'Standing is the label for your rep band in that world. It gates '
          'some world tools when those modules are enabled.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.worldPrestige,
      title: 'World prestige',
      oneLiner: 'How developed a world is (1–50).',
      detail:
          'World prestige rises with active members and posts. It unlocks '
          'realm features for everyone in that world — not your personal tier.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.worldLevel,
      title: 'World growth level',
      oneLiner: 'Levels 1–10 for worlds you create — from activity score.',
      detail:
          'User-created worlds level up from posts and joins. Higher level '
          'raises the member cap.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.ascension,
      title: 'Ascension',
      oneLiner: 'Endgame flair after Elite — optional.',
      detail:
          'At high tier you may open Ascension for prestige stars and flair. '
          'It is not required to enjoy Vertiege.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.loungeAccess,
      title: 'Lounge',
      oneLiner: 'A tier-gated voice channel for deeper conversation.',
      detail:
          'Lounges unlock when your tier and world standing meet realm rules.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.worldTreasury,
      title: 'Treasury',
      oneLiner: 'Shared world funds — paused in closed beta by default.',
      detail:
          'When enabled, members can donate coins; council manages payouts.',
    ),
    ProgressionEntry(
      focus: ProgressionFocus.worldPolls,
      title: 'Polls',
      oneLiner: 'Structured votes on world decisions.',
      detail:
          'Create polls from the world polls hub when your standing allows.',
    ),
  ];

  /// Overview sheet shows only the v1 spine: XP, Tier, Streak.
  static List<ProgressionEntry> entriesFor(ProgressionFocus focus) {
    if (focus == ProgressionFocus.overview) {
      return entries
          .where((e) => e.focus == ProgressionFocus.xpAndTier)
          .toList();
    }
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
