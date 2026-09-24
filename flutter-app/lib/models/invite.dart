class WorldInvite {
  final String id;
  final String worldId;
  final String code;
  final String createdBy;
  final int maxUses;
  final int uses;
  final int? expiresAt;
  final int createdAt;

  const WorldInvite({
    required this.id,
    required this.worldId,
    required this.code,
    required this.createdBy,
    this.maxUses = 0,
    this.uses = 0,
    this.expiresAt,
    this.createdAt = 0,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().millisecondsSinceEpoch > expiresAt!;
  }

  bool get isExhausted => maxUses > 0 && uses >= maxUses;

  bool get isValid => !isExpired && !isExhausted;

  WorldInvite copyWith({
    String? id,
    String? worldId,
    String? code,
    String? createdBy,
    int? maxUses,
    int? uses,
    int? expiresAt,
    int? createdAt,
  }) => WorldInvite(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    code: code ?? this.code,
    createdBy: createdBy ?? this.createdBy,
    maxUses: maxUses ?? this.maxUses,
    uses: uses ?? this.uses,
    expiresAt: expiresAt ?? this.expiresAt,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'worldId': worldId,
    'code': code,
    'createdBy': createdBy,
    'maxUses': maxUses,
    'uses': uses,
    'expiresAt': expiresAt,
    'createdAt': createdAt,
  };

  static WorldInvite fromJson(Map<String, dynamic> json) => WorldInvite(
    id: json['id'] ?? '',
    worldId: json['worldId'] ?? '',
    code: json['code'] ?? '',
    createdBy: json['createdBy'] ?? '',
    maxUses: json['maxUses'] ?? 0,
    uses: json['uses'] ?? 0,
    expiresAt: json['expiresAt'],
    createdAt: json['createdAt'] ?? 0,
  );

  static WorldInvite fromSupabase(Map<String, dynamic> data) => WorldInvite(
    id: data['id']?.toString() ?? '',
    worldId: data['world_id']?.toString() ?? '',
    code: data['code']?.toString() ?? '',
    createdBy: data['created_by']?.toString() ?? '',
    maxUses: data['max_uses'] as int? ?? 0,
    uses: data['uses'] as int? ?? 0,
    expiresAt: data['expires_at'] as int?,
    createdAt: data['created_at'] as int? ?? 0,
  );
}
