enum WorldJobApplicationStatus { pending, accepted, rejected, withdrawn }

class WorldJobApplication {
  final String id;
  final String jobId;
  final String applicantId;
  final String message;
  final WorldJobApplicationStatus status;
  final DateTime createdAt;

  const WorldJobApplication({
    required this.id,
    required this.jobId,
    required this.applicantId,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == WorldJobApplicationStatus.pending;

  factory WorldJobApplication.fromSupabase(Map<String, dynamic> row) {
    return WorldJobApplication(
      id: row['id'] as String,
      jobId: row['job_id'] as String,
      applicantId: row['applicant_id'] as String? ?? '',
      message: row['message'] as String? ?? '',
      status: _parseStatus(row['status'] as String?),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static WorldJobApplicationStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'accepted':
        return WorldJobApplicationStatus.accepted;
      case 'rejected':
        return WorldJobApplicationStatus.rejected;
      case 'withdrawn':
        return WorldJobApplicationStatus.withdrawn;
      default:
        return WorldJobApplicationStatus.pending;
    }
  }
}
