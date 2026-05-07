class ChannelMessage {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String? imageUrl;
  final int createdAt;

  const ChannelMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  ChannelMessage copyWith({
    String? id,
    String? channelId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    String? imageUrl,
    int? createdAt,
  }) =>
      ChannelMessage(
        id: id ?? this.id,
        channelId: channelId ?? this.channelId,
        senderId: senderId ?? this.senderId,
        senderName: senderName ?? this.senderName,
        senderAvatar: senderAvatar ?? this.senderAvatar,
        content: content ?? this.content,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'channelId': channelId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'content': content,
        'imageUrl': imageUrl,
        'createdAt': createdAt,
      };

  static ChannelMessage fromJson(Map<String, dynamic> json) => ChannelMessage(
        id: json['id'] ?? '',
        channelId: json['channelId'] ?? '',
        senderId: json['senderId'] ?? '',
        senderName: json['senderName'] ?? '',
        senderAvatar: json['senderAvatar'],
        content: json['content'] ?? '',
        imageUrl: json['imageUrl'],
        createdAt: json['createdAt'] ?? 0,
      );
}
