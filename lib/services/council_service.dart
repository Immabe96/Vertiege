import 'dart:math';
import 'supabase.dart';

class CouncilMember {
  final String residentId;
  final String residentName;
  final int rep;
  final int tier;
  final int lastSeenAt;

  const CouncilMember({
    required this.residentId,
    required this.residentName,
    required this.rep,
    required this.tier,
    required this.lastSeenAt,
  });
}

class CouncilAction {
  final String type; // 'eject', 'elect'
  final String? residentId;
  final String? residentName;
  final String? details;

  const CouncilAction({
    required this.type,
    this.residentId,
    this.residentName,
    this.details,
  });
}

class CouncilService {
  static const int inactivityDays = 15;
  static const int councilMinRep = 5000;
  static const int ejectedRep = 4999;

  /// Check inactivity for a world's council and sovereign.
  /// Returns actions taken (ejections, elections).
  static Future<List<CouncilAction>> checkWorld(String worldId) async {
    if (!isSupabaseConfigured()) return [];

    final client = getSupabase();
    final actions = <CouncilAction>[];

    // Fetch world data
    final worldData = await client
        .from('worlds')
        .select()
        .eq('id', worldId)
        .maybeSingle();

    if (worldData == null) return [];

    // Dominion/custom worlds are creator-governed, not council-governed.
    if (worldData['type'] == 'dominion') return [];

    final sovereignId = worldData['sovereign_id'] as String? ?? '';

    // Fetch all members with council-level rep (rep >= 5000)
    final councilData = await client
        .from('world_members')
        .select()
        .eq('world_id', worldId)
        .gte('rep', councilMinRep)
        .order('rep', ascending: false);

    if ((councilData as List).isEmpty) return [];

    final members = (councilData as List).cast<Map<String, dynamic>>();
    final cutoff = DateTime.now().millisecondsSinceEpoch - (inactivityDays * 86400000);

    // Get profiles for all council members
    final memberIds = members.map((m) => m['resident_id'] as String).toList();
    final profiles = await client
        .from('profiles')
        .select()
        .inFilter('id', memberIds);

    final profileMap = <String, Map<String, dynamic>>{};
    for (final p in (profiles as List)) {
      profileMap[p['id'] as String] = p as Map<String, dynamic>;
    }

    // Check sovereign inactivity
    final sovProfile = profileMap[sovereignId];
    final sovLastSeen = sovProfile?['last_seen_at'] as int? ?? 0;
    final sovereignInactive = sovLastSeen > 0 && sovLastSeen < cutoff;

    // Collect active council members (excluding sovereign for election purposes)
    final activeCouncil = <CouncilMember>[];
    final ejectedIds = <String>{};

    for (final m in members) {
      final rid = m['resident_id'] as String;
      final profile = profileMap[rid];
      final lastSeen = profile?['last_seen_at'] as int? ?? 0;
      final tier = profile?['tier'] as int? ?? 1;

      if (lastSeen > 0 && lastSeen < cutoff) {
        // Inactive — eject
        await _ejectMember(worldId, rid);
        ejectedIds.add(rid);
        actions.add(CouncilAction(
          type: 'eject',
          residentId: rid,
          residentName: m['resident_name'] as String? ?? 'Unknown',
          details: 'Inactive for $inactivityDays+ days',
        ));
      } else if (!ejectedIds.contains(rid)) {
        activeCouncil.add(CouncilMember(
          residentId: rid,
          residentName: m['resident_name'] as String? ?? 'Unknown',
          rep: m['rep'] as int? ?? 0,
          tier: tier,
          lastSeenAt: lastSeen,
        ));
      }
    }

    // If sovereign was ejected, run election
    if (sovereignInactive || ejectedIds.contains(sovereignId)) {
      if (activeCouncil.isNotEmpty) {
        final newSovereign = _electSovereign(activeCouncil);
        if (newSovereign.residentId != sovereignId) {
          await _updateSovereign(worldId, newSovereign.residentId, newSovereign.residentName);
          actions.add(CouncilAction(
            type: 'elect',
            residentId: newSovereign.residentId,
            residentName: newSovereign.residentName,
            details: 'Elected as new Sovereign',
          ));
        }
      }
    }

    return actions;
  }

  /// Elect a sovereign from council members.
  /// Each votes for themselves. If everyone votes for themselves (deadlock),
  /// the system picks one randomly.
  static String _electSovereignId(List<CouncilMember> council) {
    if (council.isEmpty) return '';
    if (council.length == 1) return council.first.residentId;

    // Simulate voting: each member votes for themselves
    final votes = <String, int>{};
    for (final member in council) {
      votes[member.residentId] = 1; // self-vote
    }

    final maxVotes = votes.values.reduce(max);
    final topCandidates = votes.entries
        .where((e) => e.value == maxVotes)
        .map((e) => e.key)
        .toList();

    if (topCandidates.length == 1) return topCandidates.first;

    // Deadlock — all voted for themselves. System picks randomly.
    final random = Random();
    return topCandidates[random.nextInt(topCandidates.length)];
  }

  static CouncilMember _electSovereign(List<CouncilMember> council) {
    final id = _electSovereignId(council);
    return council.firstWhere((m) => m.residentId == id);
  }

  static Future<void> _ejectMember(String worldId, String residentId) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    // Drop rep just below council threshold
    await client
        .from('world_members')
        .update({'rep': ejectedRep})
        .eq('world_id', worldId)
        .eq('resident_id', residentId);
  }

  static Future<void> _updateSovereign(
      String worldId, String sovereignId, String sovereignName) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client
        .from('worlds')
        .update({
          'sovereign_id': sovereignId,
          'sovereign_name': sovereignName,
        })
        .eq('id', worldId);
  }

  /// Promote the next highest-rep members to council to fill vacancies.
  /// Called after ejections to ensure council stays at 11 members.
  static Future<List<String>> fillCouncilSeats(String worldId, int currentCouncilCount) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();

    final seatsNeeded = 11 - currentCouncilCount;
    if (seatsNeeded <= 0) return [];

    // Get top non-council members by rep
    final data = await client
        .from('world_members')
        .select()
        .eq('world_id', worldId)
        .lt('rep', councilMinRep)
        .order('rep', ascending: false)
        .limit(seatsNeeded);

    final promoted = <String>[];
    for (final m in (data as List)) {
      final rid = m['resident_id'] as String;
      await client
          .from('world_members')
          .update({'rep': councilMinRep})
          .eq('world_id', worldId)
          .eq('resident_id', rid);
      promoted.add(rid);
    }

    return promoted;
  }
}
