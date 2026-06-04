import '../models/season_cohort.dart';
import 'supabase.dart';

class SeasonCohortService {
  static Future<SeasonCohortSummary?> ensureMembership(String worldId) async {
    if (!isSupabaseConfigured()) return null;
    final result = await getSupabase().rpc(
      'ensure_season_cohort_membership',
      params: {'p_world_id': worldId},
    );
    return _parseCohortFromRpc(result);
  }

  static Future<SeasonCohortSummary?> getSummary(String worldId) async {
    if (!isSupabaseConfigured()) return null;
    final result = await getSupabase().rpc(
      'get_season_cohort_summary',
      params: {'p_world_id': worldId},
    );
    if (result is! Map) return null;
    final map = Map<String, dynamic>.from(result);
    if (map['success'] != true) return null;
    final cohort = map['cohort'];
    if (cohort == null) return null;
    return SeasonCohortSummary.fromJson(
      Map<String, dynamic>.from(cohort as Map),
    );
  }

  static SeasonCohortSummary? _parseCohortFromRpc(dynamic result) {
    if (result is! Map) return null;
    final map = Map<String, dynamic>.from(result);
    if (map['success'] != true) return null;
    final id = map['cohort_id'] as String?;
    final seasonId = map['season_id'] as String?;
    if (id == null || seasonId == null) return null;
    return SeasonCohortSummary(
      id: id,
      seasonId: seasonId,
      worldId: map['world_id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? 'Cohort',
      memberCount: (map['member_count'] as num?)?.toInt() ?? 0,
    );
  }
}
