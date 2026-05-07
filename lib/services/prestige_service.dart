import '../config/tiers.dart';
import '../models/post.dart';
import '../models/world.dart';
import 'supabase.dart';

class PrestigeService {
  /// Recalculate and persist prestige for a world.
  /// Returns the new prestige value.
  static Future<int> recalculateForWorld({
    required String worldId,
    required World world,
    required int memberCount,
    required double avgMemberTier,
    required int sovereignTier,
    required List<Post> recentPosts,
  }) async {
    final weekAgo = DateTime.now().millisecondsSinceEpoch - (7 * 86400000);

    final worldPosts = recentPosts.where((p) => p.worldId == worldId).toList();
    final weeklyPosts = worldPosts.where((p) => p.timestamp > weekAgo).length;
    final weeklyReactions = worldPosts
        .where((p) => p.timestamp > weekAgo)
        .fold<int>(0, (sum, p) => sum + p.reactions.values.fold(0, (a, b) => a + b));

    final newPrestige = calculatePrestige(
      sovereignTier: sovereignTier,
      avgMemberTier: avgMemberTier,
      weeklyPosts: weeklyPosts,
      weeklyReactions: weeklyReactions,
      memberCount: memberCount,
    );

    // Only update if prestige actually changed
    if (newPrestige != world.prestige) {
      await _persistPrestige(worldId, newPrestige);
    }

    return newPrestige;
  }

  /// Compute average tier from a map of resident ID → tier value.
  static double computeAvgTier(Map<String, int> memberTiers) {
    if (memberTiers.isEmpty) return 1.0;
    final sum = memberTiers.values.fold<int>(0, (a, b) => a + b);
    return sum / memberTiers.length;
  }

  /// Get the sovereign tier for prestige calculation.
  /// Returns a reasonable default for NPC sovereigns (hardcoded worlds).
  static int resolveSovereignTier(String sovereignId, Map<String, int> memberTiers, World world) {
    // Real resident sovereign
    if (memberTiers.containsKey(sovereignId)) {
      return memberTiers[sovereignId]!;
    }
    // NPC sovereign — estimate from world's required tier or prestige bracket
    if (world.type == WorldType.wealth) {
      return world.requiredTier ?? (world.prestige > 35 ? 5 : world.prestige > 20 ? 4 : world.prestige > 10 ? 3 : 2);
    }
    if (world.type == WorldType.profession) {
      return (world.prestige > 30 ? 5 : world.prestige > 20 ? 4 : world.prestige > 10 ? 3 : 2);
    }
    return 3; // dominion worlds — sovereign is the creator
  }

  static Future<void> _persistPrestige(String worldId, int prestige) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client
        .from('worlds')
        .update({'prestige': prestige})
        .eq('id', worldId);
  }
}
