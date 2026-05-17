class WorldChallenge {
  final String id;
  final String worldId;
  final String title;
  final String description;
  final String challengeType;
  final int targetValue;
  final int currentValue;
  final int rewardXp;
  final int rewardCurrency;
  final DateTime startsAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;

  const WorldChallenge({
    required this.id,
    required this.worldId,
    required this.title,
    required this.description,
    this.challengeType = 'individual',
    this.targetValue = 0,
    this.currentValue = 0,
    this.rewardXp = 0,
    this.rewardCurrency = 0,
    required this.startsAt,
    this.expiresAt,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
  });

  double get progressPct {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  bool get isCompleted => currentValue >= targetValue;
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'world_id': worldId,
    'title': title,
    'description': description,
    'challenge_type': challengeType,
    'target_value': targetValue,
    'current_value': currentValue,
    'reward_xp': rewardXp,
    'reward_currency': rewardCurrency,
    'starts_at': startsAt.toIso8601String(),
    if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
    'is_active': isActive,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
  };

  factory WorldChallenge.fromJson(Map<String, dynamic> json) => WorldChallenge(
    id: json['id'] ?? '',
    worldId: json['world_id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    challengeType: json['challenge_type'] ?? 'individual',
    targetValue: (json['target_value'] as num?)?.toInt() ?? 0,
    currentValue: (json['current_value'] as num?)?.toInt() ?? 0,
    rewardXp: (json['reward_xp'] as num?)?.toInt() ?? 0,
    rewardCurrency: (json['reward_currency'] as num?)?.toInt() ?? 0,
    startsAt: _parseDate(json['starts_at']),
    expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
    isActive: json['is_active'] != false,
    createdBy: json['created_by'] ?? '',
    createdAt: _parseDate(json['created_at']),
  );

  static WorldChallenge fromSupabase(Map<String, dynamic> data) => WorldChallenge(
    id: data['id'] ?? '',
    worldId: data['world_id'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    challengeType: data['challenge_type'] ?? 'individual',
    targetValue: (data['target_value'] as num?)?.toInt() ?? 0,
    currentValue: (data['current_value'] as num?)?.toInt() ?? 0,
    rewardXp: (data['reward_xp'] as num?)?.toInt() ?? 0,
    rewardCurrency: (data['reward_currency'] as num?)?.toInt() ?? 0,
    startsAt: _parseDate(data['starts_at']),
    expiresAt: data['expires_at'] != null ? DateTime.tryParse(data['expires_at']) : null,
    isActive: data['is_active'] != false,
    createdBy: data['created_by'] ?? '',
    createdAt: _parseDate(data['created_at']),
  );

  static DateTime _parseDate(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }
}

class ChallengeProgress {
  final String id;
  final String challengeId;
  final String residentId;
  final int contribution;
  final bool completed;
  final DateTime? completedAt;

  const ChallengeProgress({
    required this.id,
    required this.challengeId,
    required this.residentId,
    this.contribution = 0,
    this.completed = false,
    this.completedAt,
  });

  static ChallengeProgress fromSupabase(Map<String, dynamic> data) => ChallengeProgress(
    id: data['id'] ?? '',
    challengeId: data['challenge_id'] ?? '',
    residentId: data['resident_id'] ?? '',
    contribution: (data['contribution'] as num?)?.toInt() ?? 0,
    completed: data['completed'] == true,
    completedAt: data['completed_at'] != null ? DateTime.tryParse(data['completed_at']) : null,
  );
}
