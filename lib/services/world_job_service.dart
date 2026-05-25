import '../models/world_job.dart';
import 'supabase.dart';

class WorldJobService {
  static Future<List<WorldJob>> fetchJobs(
    String worldId, {
    bool openOnly = true,
  }) async {
    if (!isSupabaseConfigured()) return [];
    var query = getSupabase()
        .from('world_jobs')
        .select()
        .eq('world_id', worldId);
    if (openOnly) {
      query = query.eq('status', 'open');
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((e) => WorldJob.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<WorldJob?> createJob({
    required String worldId,
    required String title,
    required String description,
    required String roleLabel,
    int minStandingLevel = 3,
    int minTier = 2,
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase required to post jobs.');
    }
    final userId = getSupabase().auth.currentUser?.id;
    if (userId == null) throw StateError('Not authenticated');

    final row = await getSupabase()
        .from('world_jobs')
        .insert({
          'world_id': worldId,
          'title': title,
          'description': description,
          'role_label': roleLabel,
          'min_standing_level': minStandingLevel,
          'min_tier': minTier,
          'created_by': userId,
        })
        .select()
        .single();

    return WorldJob.fromSupabase(row);
  }

  static Future<void> updateStatus(String jobId, WorldJobStatus status) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase()
        .from('world_jobs')
        .update({'status': status.name})
        .eq('id', jobId);
  }
}
