import '../utils/id_generator.dart';

class MutationOutboxItem {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final int retryCount;
  final String? error;

  MutationOutboxItem({
    String? id,
    required this.type,
    required this.payload,
    DateTime? createdAt,
    this.lastAttemptAt,
    this.retryCount = 0,
    this.error,
  }) : id = id ?? generateId(),
       createdAt = createdAt ?? DateTime.now();

  MutationOutboxItem copyWith({
    DateTime? lastAttemptAt,
    int? retryCount,
    String? error,
  }) => MutationOutboxItem(
    id: id,
    type: type,
    payload: payload,
    createdAt: createdAt,
    lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    retryCount: retryCount ?? this.retryCount,
    error: error ?? this.error,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'lastAttemptAt': lastAttemptAt?.toIso8601String(),
    'retryCount': retryCount,
    'error': error,
  };

  factory MutationOutboxItem.fromJson(Map<String, dynamic> json) {
    return MutationOutboxItem(
      id: json['id'] as String?,
      type: json['type'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      lastAttemptAt: DateTime.tryParse(json['lastAttemptAt']?.toString() ?? ''),
      retryCount: json['retryCount'] as int? ?? 0,
      error: json['error'] as String?,
    );
  }
}
