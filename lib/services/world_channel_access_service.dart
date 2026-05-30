import '../config/tiers.dart';
import '../models/channel.dart';
import '../models/resident.dart';
import '../models/world.dart';
import 'permission_service.dart';

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
    if (!isLounge && !isCampfire) return const ChannelAccessDecision.open();

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
