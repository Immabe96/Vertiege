class ChannelMessage {
  final String id;
  final String channelId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String? imageUrl;
  final bool isPinned;
  final String? threadId;
  final int threadCount;
  final bool isThreadStarter;
  final int createdAt;

  const ChannelMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.imageUrl,
    this.isPinned = false,
    this.threadId,
    this.threadCount = 0,
    this.isThreadStarter = false,
    required this.createdAt,
  });

  bool get hasThread => threadCount > 0;

  ChannelMessage copyWith({
    String? id,
    String? channelId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    String? imageUrl,
    bool? isPinned,
    String? threadId,
    int? threadCount,
    bool? isThreadStarter,
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
        isPinned: isPinned ?? this.isPinned,
        threadId: threadId ?? this.threadId,
        threadCount: threadCount ?? this.threadCount,
        isThreadStarter: isThreadStarter ?? this.isThreadStarter,
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
        'isPinned': isPinned,
        'threadId': threadId,
        'threadCount': threadCount,
        'isThreadStarter': isThreadStarter,
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
        isPinned: json['isPinned'] ?? false,
        threadId: json['threadId'],
        threadCount: json['threadCount'] ?? 0,
        isThreadStarter: json['isThreadStarter'] ?? false,
        createdAt: json['createdAt'] ?? 0,
      );
}
