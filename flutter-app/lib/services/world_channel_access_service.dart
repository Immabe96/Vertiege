import '../config/tiers.dart';
import '../models/channel.dart';
import '../models/resident.dart';
import '../models/world.dart';
import 'feature_flags.dart';
import 'permission_service.dart';

/// Parses optional tier gate from channel name or description.
int? requiredTierForChannel(WorldChannel channel) {
  final name = channel.name.toLowerCase();
  if (name.contains('apex')) return 5;
  if (name.contains('old-money') || name.contains('oldmoney')) return 4;
  if (name.contains('elite')) return 3;
  if (name.contains('high-roller') || name.contains('highroller')) return 2;

  final desc = channel.description ?? '';
  final match = RegExp(r'[Tt]ier\s*(\d)\+?').firstMatch(desc);
  if (match != null) return int.tryParse(match.group(1)!);

  return null;
}

class ChannelAccessDecision {
  final bool canOpen;
  final String? reason;

  const ChannelAccessDecision.open() : canOpen = true, reason = null;

  const ChannelAccessDecision.locked(this.reason) : canOpen = false;
}

class WorldChannelAccessService {
  static const loungePrestige = 10;
  static const campfirePrestige = 25;
  static const loungeStandingLevel = 4;
  static const loungeStandingLabel = 'Veteran';

  static bool isLoungeChannel(WorldChannel channel) =>
      channel.name.toLowerCase() == 'lounge';

  static bool isCampfireChannel(WorldChannel channel) =>
      channel.channelType == ChannelType.voice;

  static ChannelAccessDecision decision({
    required World world,
    required WorldChannel channel,
    required WorldFeatures features,
    required Resident? resident,
  }) {
    final isLounge = isLoungeChannel(channel);
    final isCampfire = isCampfireChannel(channel);
    final tierGate = requiredTierForChannel(channel);

    if (tierGate != null) {
      if (resident == null) {
        final label = tierNames[tierGate] ?? 'Tier $tierGate';
        return ChannelAccessDecision.locked(
          'Requires $label tier to enter.',
        );
      }
      if (resident.tier.value < tierGate) {
        final label = tierNames[tierGate] ?? 'Tier $tierGate';
        return ChannelAccessDecision.locked(
          'Requires $label tier (you are ${tierNames[resident.tier.value] ?? 'Tier ${resident.tier.value}'}).',
        );
      }
    }

    if (!isLounge && !isCampfire) return const ChannelAccessDecision.open();

    if (isCampfire && !FeatureFlags.campfireEnabled) {
      return const ChannelAccessDecision.locked(
        'Campfire voice is coming soon.',
      );
    }

    if (isLounge && !features.lounge) {
      return const ChannelAccessDecision.locked(
        'Lounge unlocks at world prestige $loungePrestige.',
      );
    }
    if (isCampfire && !features.audioRooms) {
      return const ChannelAccessDecision.locked(
        'Campfire unlocks at world prestige $campfirePrestige.',
      );
    }
    if (resident == null) {
      return const ChannelAccessDecision.locked(
        'Sign in and earn world standing to enter.',
      );
    }

    final standing = WorldPermissions.resolveStanding(
      resident,
      world.id,
      world.sovereignId,
    );
    if (standing.level < loungeStandingLevel) {
      final needed = standingLevels[loungeStandingLevel - 1].minRep;
      return ChannelAccessDecision.locked(
        'Reach $loungeStandingLabel standing ($needed rep) in this world.',
      );
    }
    return const ChannelAccessDecision.open();
  }
}
