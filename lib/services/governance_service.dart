import 'supabase.dart';

class GovernanceProposal {
  final String id;
  final String worldId;
  final String proposalType;
  final String status;
  final String requestedBy;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const GovernanceProposal({
    required this.id,
    required this.worldId,
    required this.proposalType,
    required this.status,
    required this.requestedBy,
    required this.payload,
    required this.createdAt,
  });

  factory GovernanceProposal.fromJson(Map<String, dynamic> json) {
    return GovernanceProposal(
      id: json['id'] as String,
      worldId: json['world_id'] as String,
      proposalType: json['proposal_type'] as String,
      status: json['status'] as String,
      requestedBy: json['requested_by'] as String,
      payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class GovernanceService {
  static Future<Map<String, String>> _profileNames(Iterable<String> ids) async {
    final unique = ids.where((id) => id.isNotEmpty).toSet().toList();
    if (!isSupabaseConfigured() || unique.isEmpty) return {};
    final data = await getSupabase()
        .from('profiles')
        .select('id, name')
        .inFilter('id', unique);
    final map = <String, String>{};
    for (final row in data as List) {
      final m = row as Map<String, dynamic>;
      final id = m['id'] as String?;
      if (id == null) continue;
      map[id] = (m['name'] as String?)?.trim().isNotEmpty == true
          ? (m['name'] as String).trim()
          : 'Resident';
    }
    return map;
  }

  static Future<({List<GovernanceProposal> proposals, Map<String, String> names})>
      listPendingEnriched(String worldId) async {
    final proposals = await listPending(worldId);
    final ids = <String>{
      for (final p in proposals) p.requestedBy,
      for (final p in proposals)
        if (p.proposalType == 'rank_change')
          p.payload['resident_id'] as String? ?? '',
    };
    final names = await _profileNames(ids);
    return (proposals: proposals, names: names);
  }

  static Future<List<GovernanceProposal>> listPending(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('governance_proposals')
        .select()
        .eq('world_id', worldId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => GovernanceProposal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<String?> requestTreasuryWithdrawal({
    required String worldId,
    required int amount,
    required String description,
  }) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final result = await client.rpc(
      'request_treasury_withdrawal',
      params: {
        'p_world_id': worldId,
        'p_amount': amount,
        'p_description': description,
      },
    );
    if (result is! Map) return null;
    final map = Map<String, dynamic>.from(result);
    if (map['success'] != true) return map['error'] as String?;
    if (map['executed'] == true) return null;
    return 'pending';
  }

  static Future<({bool executed, String? error})> requestJobPublish({
    required String worldId,
    required String title,
    required String description,
    String roleLabel = 'Contributor',
    int minStandingLevel = 3,
    int minTier = 2,
  }) async {
    if (!isSupabaseConfigured()) {
      return (executed: false, error: 'Supabase unavailable');
    }
    final result = await getSupabase().rpc(
      'request_job_publish',
      params: {
        'p_world_id': worldId,
        'p_title': title,
        'p_description': description,
        'p_role_label': roleLabel,
        'p_min_standing_level': minStandingLevel,
        'p_min_tier': minTier,
      },
    );
    if (result is! Map) return (executed: false, error: 'Unexpected response');
    final map = Map<String, dynamic>.from(result);
    if (map['success'] != true) {
      return (executed: false, error: map['error'] as String? ?? 'Request failed');
    }
    return (executed: map['executed'] == true, error: null);
  }

  static Future<({bool executed, String? error})> requestRankChange({
    required String worldId,
    required String residentId,
    required String rankId,
    required bool assign,
  }) async {
    if (!isSupabaseConfigured()) {
      return (executed: false, error: 'Supabase unavailable');
    }
    final result = await getSupabase().rpc(
      'request_rank_change',
      params: {
        'p_world_id': worldId,
        'p_resident_id': residentId,
        'p_rank_id': rankId,
        'p_action': assign ? 'assign' : 'remove',
      },
    );
    if (result is! Map) return (executed: false, error: 'Unexpected response');
    final map = Map<String, dynamic>.from(result);
    if (map['success'] != true) {
      return (executed: false, error: map['error'] as String? ?? 'Request failed');
    }
    return (executed: map['executed'] == true, error: null);
  }

  static Future<String?> reviewProposal({
    required String proposalId,
    required bool approve,
    String note = '',
  }) async {
    if (!isSupabaseConfigured()) return 'Supabase unavailable';
    final client = getSupabase();
    final result = await client.rpc(
      'review_governance_proposal',
      params: {
        'p_proposal_id': proposalId,
        'p_approve': approve,
        'p_note': note,
      },
    );
    if (result is! Map) return 'Unexpected response';
    final map = Map<String, dynamic>.from(result);
    if (map['success'] == true) return null;
    return map['error'] as String? ?? 'Review failed';
  }
}
