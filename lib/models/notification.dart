enum NotificationType {
  like,
  comment,
  worldUnlocked,
  tierUpgrade,
  welcome,
  modAction,
  ranking,
  streakReminder,
  reactionMilestone,
  mention,
  dmMessage,
  allegianceRequest,
  achievementApproved,
  achievementRejected,
  jobApplicationAccepted,
  jobApplicationRejected,
  governanceProposalApproved,
  governanceProposalRejected,
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String message;
  final String? worldId;
  final String? postId;
  final String? roomId;
  final String? allyRequestId;
  final bool read;
  final int createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    this.worldId,
    this.postId,
    this.roomId,
    this.allyRequestId,
    this.read = false,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? message,
    String? worldId,
    String? postId,
    String? roomId,
    String? allyRequestId,
    bool? read,
    int? createdAt,
  }) => AppNotification(
    id: id ?? this.id,
    type: type ?? this.type,
    message: message ?? this.message,
    worldId: worldId ?? this.worldId,
    postId: postId ?? this.postId,
    roomId: roomId ?? this.roomId,
    allyRequestId: allyRequestId ?? this.allyRequestId,
    read: read ?? this.read,
    createdAt: createdAt ?? this.createdAt,
  );

  static NotificationType typeFromString(String value) {
    return switch (value) {
      'like' => NotificationType.like,
      'comment' => NotificationType.comment,
      'worldUnlocked' => NotificationType.worldUnlocked,
      'tierUpgrade' => NotificationType.tierUpgrade,
      'welcome' => NotificationType.welcome,
      'modAction' => NotificationType.modAction,
      'ranking' => NotificationType.ranking,
      'streakReminder' => NotificationType.streakReminder,
      'reactionMilestone' => NotificationType.reactionMilestone,
      'mention' => NotificationType.mention,
      'dmMessage' => NotificationType.dmMessage,
      'dm_message' => NotificationType.dmMessage,
      'allegianceRequest' => NotificationType.allegianceRequest,
      'achievementApproved' => NotificationType.achievementApproved,
      'achievementRejected' => NotificationType.achievementRejected,
      'jobApplicationAccepted' => NotificationType.jobApplicationAccepted,
      'job_application_accepted' => NotificationType.jobApplicationAccepted,
      'jobApplicationRejected' => NotificationType.jobApplicationRejected,
      'job_application_rejected' => NotificationType.jobApplicationRejected,
      'governanceProposalApproved' =>
        NotificationType.governanceProposalApproved,
      'governance_proposal_approved' =>
        NotificationType.governanceProposalApproved,
      'governanceProposalRejected' =>
        NotificationType.governanceProposalRejected,
      'governance_proposal_rejected' =>
        NotificationType.governanceProposalRejected,
      _ => NotificationType.like,
    };
  }

  static AppNotification fromSupabase(Map<String, dynamic> data) =>
      AppNotification(
        id: data['id'] ?? '',
        type: typeFromString(data['type'] ?? ''),
        message: data['message'] ?? '',
        worldId: data['world_id'],
        postId: data['post_id'],
        roomId: data['room_id'],
        allyRequestId: data['ally_request_id'],
        read: data['read'] ?? false,
        createdAt: data['created_at'] != null
            ? DateTime.tryParse(data['created_at'])?.millisecondsSinceEpoch ?? 0
            : 0,
      );

  Map<String, dynamic> toSupabase(String recipientId) => {
    'id': id,
    'recipient_id': recipientId,
    'type': type.name,
    'message': message,
    'world_id': worldId,
    'post_id': postId,
    'room_id': roomId,
    'ally_request_id': allyRequestId,
    'read': read,
    'created_at': DateTime.fromMillisecondsSinceEpoch(
      createdAt,
    ).toIso8601String(),
  };
}
