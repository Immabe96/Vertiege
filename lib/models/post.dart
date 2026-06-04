import 'resident.dart';
import 'sync_status.dart';

class Comment {
  final String id;
  final String residentId;
  final String residentName;
  final String? parentId; // null = top-level, non-null = reply to parent
  final String content;
  final int timestamp;
  final bool isEdited;
  final int tierAtPosting;

  const Comment({
    required this.id,
    required this.residentId,
    required this.residentName,
    this.parentId,
    required this.content,
    required this.timestamp,
    this.isEdited = false,
    this.tierAtPosting = 1,
  });

  bool get isReply => parentId != null;

  Comment copyWith({
    String? id,
    String? residentId,
    String? residentName,
    String? parentId,
    String? content,
    int? timestamp,
    bool? isEdited,
    int? tierAtPosting,
  }) => Comment(
    id: id ?? this.id,
    residentId: residentId ?? this.residentId,
    residentName: residentName ?? this.residentName,
    parentId: parentId ?? this.parentId,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
    isEdited: isEdited ?? this.isEdited,
    tierAtPosting: tierAtPosting ?? this.tierAtPosting,
  );
}

class PollOption {
  final String id;
  final String text;
  final int voteCount;

  const PollOption({required this.id, required this.text, this.voteCount = 0});

  PollOption copyWith({String? id, String? text, int? voteCount}) => PollOption(
    id: id ?? this.id,
    text: text ?? this.text,
    voteCount: voteCount ?? this.voteCount,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'voteCount': voteCount,
  };

  factory PollOption.fromJson(Map<String, dynamic> json) => PollOption(
    id: json['id'] ?? '',
    text: json['text'] ?? '',
    voteCount: json['voteCount'] ?? 0,
  );
}

class Poll {
  final String question;
  final List<PollOption> options;
  final bool isMultiChoice;
  final List<String> votedResidentIds;

  const Poll({
    required this.question,
    required this.options,
    this.isMultiChoice = false,
    this.votedResidentIds = const [],
  });

  int get totalVotes => options.fold<int>(0, (sum, o) => sum + o.voteCount);

  Poll copyWith({
    String? question,
    List<PollOption>? options,
    bool? isMultiChoice,
    List<String>? votedResidentIds,
  }) => Poll(
    question: question ?? this.question,
    options: options ?? this.options,
    isMultiChoice: isMultiChoice ?? this.isMultiChoice,
    votedResidentIds: votedResidentIds ?? this.votedResidentIds,
  );

  Map<String, dynamic> toJson() => {
    'question': question,
    'options': options.map((o) => o.toJson()).toList(),
    'isMultiChoice': isMultiChoice,
    'votedResidentIds': votedResidentIds,
  };

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
    question: json['question'] ?? '',
    options:
        (json['options'] as List<dynamic>?)
            ?.map((o) => PollOption.fromJson(o as Map<String, dynamic>))
            .toList() ??
        [],
    isMultiChoice: json['isMultiChoice'] ?? false,
    votedResidentIds:
        (json['votedResidentIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
  );
}

class Post {
  final String id;
  final String worldId;
  final String residentId;
  final String residentName;
  final String? authorDisplayTitle;
  final String residentAvatar;
  final String content;
  final String? imageUri;
  final List<String>? imageUris;
  final int timestamp;
  final ResidentTier tierAtPosting;
  final Map<String, int> reactions;
  final List<Comment> comments;
  final bool isAnnouncement;
  final bool isPinned;
  final bool isEdited;
  final String? repostOf;
  final List<String> mentions;
  final List<String> hashtags;
  final Poll? poll;

  /// Whether this post is a Sovereign Decree (styled announcement from sovereign).
  final bool isDecree;

  /// If non-null, this post is an event announcement.
  final String? eventTitle;
  final int? eventStartsAt;
  final List<String> eventRsvpIds;

  /// Post moderation status: 'published', 'pending_review', 'flagged', 'removed'.
  final String status;

  /// If non-null, the time at which this post should be published.
  final DateTime? scheduledFor;

  /// Awards given to this post by residents.
  final List<String> awards;

  /// Number of failed publish attempts for scheduled posts.
  final int failedPublishes;

  /// Local synchronization state for optimistic mutations.
  final SyncStatus syncStatus;
  final String? localTempId;
  final String? syncError;

  const Post({
    required this.id,
    required this.worldId,
    required this.residentId,
    required this.residentName,
    this.authorDisplayTitle,
    required this.residentAvatar,
    required this.content,
    this.imageUri,
    this.imageUris,
    required this.timestamp,
    this.tierAtPosting = ResidentTier.hustlers,
    this.reactions = const {},
    this.comments = const [],
    this.isAnnouncement = false,
    this.isPinned = false,
    this.isEdited = false,
    this.repostOf,
    this.mentions = const [],
    this.hashtags = const [],
    this.poll,
    this.isDecree = false,
    this.status = 'published',
    this.eventTitle,
    this.eventStartsAt,
    this.eventRsvpIds = const [],
    this.scheduledFor,
    this.awards = const [],
    this.failedPublishes = 0,
    this.syncStatus = SyncStatus.synced,
    this.localTempId,
    this.syncError,
  });

  /// Resolves the effective list of image URIs, supporting both the legacy
  /// single [imageUri] and the new multi-image [imageUris] field.
  List<String> get allImageUris {
    if (imageUris != null && imageUris!.isNotEmpty) return imageUris!;
    if (imageUri != null && imageUri!.isNotEmpty) return [imageUri!];
    return [];
  }

  bool get hasImages => allImageUris.isNotEmpty;
  bool get isEvent => eventTitle != null && eventStartsAt != null;

  /// Feed header: name plus optional profile display title.
  String get feedAuthorLabel {
    final title = authorDisplayTitle?.trim();
    if (title != null && title.isNotEmpty) {
      return '$residentName · $title';
    }
    return residentName;
  }

  Post copyWith({
    String? id,
    String? worldId,
    String? residentId,
    String? residentName,
    String? authorDisplayTitle,
    String? residentAvatar,
    String? content,
    String? imageUri,
    List<String>? imageUris,
    int? timestamp,
    ResidentTier? tierAtPosting,
    Map<String, int>? reactions,
    List<Comment>? comments,
    bool? isAnnouncement,
    bool? isPinned,
    bool? isEdited,
    String? repostOf,
    List<String>? mentions,
    List<String>? hashtags,
    Poll? poll,
    bool clearPoll = false,
    String? status,
    bool? isDecree,
    String? eventTitle,
    int? eventStartsAt,
    List<String>? eventRsvpIds,
    DateTime? scheduledFor,
    List<String>? awards,
    int? failedPublishes,
    SyncStatus? syncStatus,
    String? localTempId,
    String? syncError,
    bool clearSyncError = false,
  }) => Post(
    id: id ?? this.id,
    worldId: worldId ?? this.worldId,
    residentId: residentId ?? this.residentId,
    residentName: residentName ?? this.residentName,
    authorDisplayTitle: authorDisplayTitle ?? this.authorDisplayTitle,
    residentAvatar: residentAvatar ?? this.residentAvatar,
    content: content ?? this.content,
    imageUri: imageUri ?? this.imageUri,
    imageUris: imageUris ?? this.imageUris,
    timestamp: timestamp ?? this.timestamp,
    tierAtPosting: tierAtPosting ?? this.tierAtPosting,
    reactions: reactions ?? this.reactions,
    comments: comments ?? this.comments,
    isAnnouncement: isAnnouncement ?? this.isAnnouncement,
    isPinned: isPinned ?? this.isPinned,
    isEdited: isEdited ?? this.isEdited,
    repostOf: repostOf ?? this.repostOf,
    mentions: mentions ?? this.mentions,
    hashtags: hashtags ?? this.hashtags,
    poll: clearPoll ? null : (poll ?? this.poll),
    isDecree: isDecree ?? this.isDecree,
    status: status ?? this.status,
    eventTitle: eventTitle ?? this.eventTitle,
    eventStartsAt: eventStartsAt ?? this.eventStartsAt,
    eventRsvpIds: eventRsvpIds ?? this.eventRsvpIds,
    scheduledFor: scheduledFor ?? this.scheduledFor,
    awards: awards ?? this.awards,
    failedPublishes: failedPublishes ?? this.failedPublishes,
    syncStatus: syncStatus ?? this.syncStatus,
    localTempId: localTempId ?? this.localTempId,
    syncError: clearSyncError ? null : (syncError ?? this.syncError),
  );
}
