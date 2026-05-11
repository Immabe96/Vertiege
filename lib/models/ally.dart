enum AllegianceStatus { pending, accepted, blocked }

class Ally {
  final String id;
  final String requesterId;
  final String receiverId;
  final AllegianceStatus status;
  final int createdAt;

  const Ally({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    this.status = AllegianceStatus.pending,
    required this.createdAt,
  });

  bool get isAccepted => status == AllegianceStatus.accepted;
  bool get isPending => status == AllegianceStatus.pending;
  bool get isBlocked => status == AllegianceStatus.blocked;

  String otherId(String residentId) =>
      requesterId == residentId ? receiverId : requesterId;

  factory Ally.fromSupabase(Map<String, dynamic> data) {
    final statusStr = data['status'] ?? 'pending';
    return Ally(
      id: data['id'] ?? '',
      requesterId: data['requester_id'] ?? '',
      receiverId: data['receiver_id'] ?? '',
      status: AllegianceStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => AllegianceStatus.pending,
      ),
      createdAt: DateTime.tryParse(data['created_at'] ?? '')?.millisecondsSinceEpoch ?? 0,
    );
  }

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'requester_id': requesterId,
        'receiver_id': receiverId,
        'status': status.name,
        'created_at': DateTime.fromMillisecondsSinceEpoch(createdAt).toIso8601String(),
      };
}
