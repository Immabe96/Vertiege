enum ReportReason { spam, harassment, hateSpeech, nsfw, misinformation, other }

enum ReportStatus { pending, resolved, dismissed }

class Report {
  final String id;
  final String worldId;
  final String postId;
  final String reporterId;
  final ReportReason reason;
  final String? details;
  final int createdAt;
  final ReportStatus status;

  const Report({
    required this.id,
    required this.worldId,
    required this.postId,
    required this.reporterId,
    required this.reason,
    this.details,
    required this.createdAt,
    this.status = ReportStatus.pending,
  });

  String get reasonLabel => switch (reason) {
    ReportReason.spam => 'Spam',
    ReportReason.harassment => 'Harassment',
    ReportReason.hateSpeech => 'Hate Speech',
    ReportReason.nsfw => 'NSFW Content',
    ReportReason.misinformation => 'Misinformation',
    ReportReason.other => 'Other',
  };
}
