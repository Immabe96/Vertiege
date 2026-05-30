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
