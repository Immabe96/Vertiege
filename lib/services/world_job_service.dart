import '../models/world_job.dart';
import '../models/world_job_application.dart';
import 'governance_service.dart';
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

    final outcome = await GovernanceService.requestJobPublish(
      worldId: worldId,
      title: title,
      description: description,
      roleLabel: roleLabel,
      minStandingLevel: minStandingLevel,
      minTier: minTier,
    );
    if (outcome.error != null) {
      throw StateError(outcome.error!);
    }
    if (!outcome.executed) {
      return null;
    }

    final rows = await getSupabase()
        .from('world_jobs')
        .select()
        .eq('world_id', worldId)
        .eq('created_by', userId)
        .order('created_at', ascending: false)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return WorldJob.fromSupabase(list.first as Map<String, dynamic>);
  }

  static Future<void> updateStatus(String jobId, WorldJobStatus status) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase()
        .from('world_jobs')
        .update({'status': status.name})
        .eq('id', jobId);
  }

  static Future<WorldJobApplication> applyToJob({
    required String jobId,
    String message = '',
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase required to apply.');
    }
    final row = await getSupabase().rpc(
      'apply_to_world_job',
      params: {'p_job_id': jobId, 'p_message': message},
    );
    return WorldJobApplication.fromSupabase(row as Map<String, dynamic>);
  }

  static Future<bool> acceptApplication(String applicationId) async {
    if (!isSupabaseConfigured()) return false;
    final ok = await getSupabase().rpc(
      'accept_world_job_application',
      params: {'p_application_id': applicationId},
    );
    return ok == true;
  }

  static Future<List<WorldJobApplication>> fetchApplications(String jobId) async {
    if (!isSupabaseConfigured()) return [];
    final rows = await getSupabase()
        .from('world_job_applications')
        .select()
        .eq('job_id', jobId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => WorldJobApplication.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  /// Pending or accepted applications by the current user for the given jobs.
  static Future<Map<String, WorldJobApplicationStatus>> fetchMyApplicationStatuses(
    List<String> jobIds,
  ) async {
    if (!isSupabaseConfigured() || jobIds.isEmpty) return {};
    final userId = getSupabase().auth.currentUser?.id;
    if (userId == null) return {};

    final rows = await getSupabase()
        .from('world_job_applications')
        .select('job_id, status')
        .eq('applicant_id', userId)
        .inFilter('job_id', jobIds)
        .inFilter('status', ['pending', 'accepted']);

    final map = <String, WorldJobApplicationStatus>{};
    for (final row in rows as List) {
      final m = row as Map<String, dynamic>;
      final jobId = m['job_id'] as String;
      map[jobId] = WorldJobApplication.fromSupabase({
        'id': '',
        'job_id': jobId,
        'applicant_id': userId,
        'message': '',
        'status': m['status'],
        'created_at': null,
      }).status;
    }
    return map;
  }
}
