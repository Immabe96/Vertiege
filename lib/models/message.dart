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
  // F-01: Reply-to-message
  final String? replyToMessageId;
  final String? replyToSenderId;
  final String? replyToSenderName;
  final String? replyToContent;
  // F-02: Message reactions
  final Map<String, List<String>> reactions; // emoji -> [userId, ...]
  // F-03: Message edit/delete
  final bool isEdited;
  final int? editedAt;
  final bool isDeleted;
  // Auto-delete: seconds after creation when message should be removed
  final int? autoDeleteAfterSeconds;
  /// Local-only: message failed to reach server; tap to retry.
  final bool sendFailed;
  /// Local-only: optimistic insert pending server confirmation.
  final bool sending;

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
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyToSenderName,
    this.replyToContent,
    this.reactions = const {},
    this.isEdited = false,
    this.editedAt,
    this.isDeleted = false,
    this.autoDeleteAfterSeconds,
    this.sendFailed = false,
    this.sending = false,
  });

  bool get hasThread => threadCount > 0;
  bool get hasReply => replyToMessageId != null;
  bool get hasReactions => reactions.isNotEmpty;

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
    String? replyToMessageId,
    String? replyToSenderId,
    String? replyToSenderName,
    String? replyToContent,
    Map<String, List<String>>? reactions,
    bool? isEdited,
    int? editedAt,
    bool? isDeleted,
    int? autoDeleteAfterSeconds,
    bool? sendFailed,
    bool? sending,
  }) => ChannelMessage(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    senderId: senderId ?? this.senderId,
    senderName: senderName ?? this.senderId,
    senderAvatar: senderAvatar ?? this.senderAvatar,
    content: content ?? this.content,
    imageUrl: imageUrl ?? this.imageUrl,
    isPinned: isPinned ?? this.isPinned,
    threadId: threadId ?? this.threadId,
    threadCount: threadCount ?? this.threadCount,
    isThreadStarter: isThreadStarter ?? this.isThreadStarter,
    createdAt: createdAt ?? this.createdAt,
    replyToMessageId: replyToMessageId ?? this.replyToMessageId,
    replyToSenderId: replyToSenderId ?? this.replyToSenderId,
    replyToSenderName: replyToSenderName ?? this.replyToSenderName,
    replyToContent: replyToContent ?? this.replyToContent,
    reactions: reactions ?? this.reactions,
    isEdited: isEdited ?? this.isEdited,
    editedAt: editedAt ?? this.editedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    autoDeleteAfterSeconds:
        autoDeleteAfterSeconds ?? this.autoDeleteAfterSeconds,
    sendFailed: sendFailed ?? this.sendFailed,
    sending: sending ?? this.sending,
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
    'replyToMessageId': replyToMessageId,
    'replyToSenderId': replyToSenderId,
    'replyToSenderName': replyToSenderName,
    'replyToContent': replyToContent,
    'reactions': reactions,
    'isEdited': isEdited,
    'editedAt': editedAt,
    'isDeleted': isDeleted,
    'autoDeleteAfterSeconds': autoDeleteAfterSeconds,
    'sendFailed': sendFailed,
    'sending': sending,
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
    replyToMessageId: json['replyToMessageId'],
    replyToSenderId: json['replyToSenderId'],
    replyToSenderName: json['replyToSenderName'],
    replyToContent: json['replyToContent'],
    reactions: json['reactions'] != null
        ? (json['reactions'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          )
        : {},
    isEdited: json['isEdited'] ?? false,
    editedAt: json['editedAt'],
    isDeleted: json['isDeleted'] ?? false,
    autoDeleteAfterSeconds: json['autoDeleteAfterSeconds'],
    sendFailed: json['sendFailed'] == true,
    sending: json['sending'] == true,
  );
}
