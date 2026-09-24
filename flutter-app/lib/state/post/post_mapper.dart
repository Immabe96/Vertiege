import '../../models/post.dart';
import '../../models/resident.dart';
import '../../models/sync_status.dart';

Post postFromJson(Map<String, dynamic> json) {
  final media = (json['media'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList();
  final createdAt = json['created_at'];

  return Post(
    id: json['id'] ?? '',
    worldId: json['worldId'] ?? json['world_id'] ?? '',
    residentId:
        json['residentId'] ?? json['resident_id'] ?? json['author_id'] ?? '',
    residentName:
        json['residentName'] ??
        json['resident_name'] ??
        json['author_name'] ??
        '',
    authorDisplayTitle:
        json['authorDisplayTitle'] ??
        json['author_display_title'] as String?,
    residentAvatar:
        json['residentAvatar'] ??
        json['resident_avatar'] ??
        json['author_avatar'] ??
        '',
    content: json['content'] ?? '',
    imageUri: json['imageUri'] ?? json['image_url'],
    imageUris:
        media ??
        (json['imageUris'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList(),
    timestamp:
        json['timestamp'] ??
        (createdAt is int
            ? createdAt
            : DateTime.tryParse(
                    createdAt?.toString() ?? '',
                  )?.millisecondsSinceEpoch ??
                0),
    tierAtPosting: ResidentTier.fromValue(
      json['tierAtPosting'] ?? json['tier_at_posting'] ?? 1,
    ),
    reactions: Map<String, int>.from(json['reactions'] ?? {}),
    comments:
        (json['comments'] as List<dynamic>?)
            ?.map(
              (c) => Comment(
                id: c['id'] ?? '',
                residentId: c['residentId'] ?? '',
                residentName: c['residentName'] ?? '',
                content: c['content'] ?? '',
                timestamp: c['timestamp'] ?? 0,
                parentId: c['parentId'],
                tierAtPosting: c['tierAtPosting'] ?? 1,
              ),
            )
            .toList() ??
        [],
    isAnnouncement:
        json['isAnnouncement'] ?? json['is_announcement'] ?? false,
    isPinned: json['isPinned'] ?? json['is_pinned'] ?? false,
    isEdited: json['isEdited'] ?? json['is_edited'] ?? false,
    repostOf: json['repostOf'] ?? json['repost_of'],
    mentions:
        (json['mentions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    hashtags:
        (json['hashtags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    poll: json['poll'] != null
        ? Poll.fromJson(json['poll'] as Map<String, dynamic>)
        : null,
    status: json['status'] ?? 'published',
    isDecree: json['isDecree'] ?? json['is_decree'] ?? false,
    scheduledFor: json['scheduledFor'] != null
        ? DateTime.tryParse(json['scheduledFor'] as String)
        : null,
    awards:
        (json['awards'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [],
    failedPublishes: json['failedPublishes'] ?? 0,
    syncStatus: SyncStatusJson.fromJson(json['syncStatus']),
    localTempId: json['localTempId'] as String?,
    syncError: json['syncError'] as String?,
  );
}

Map<String, dynamic> postToJson(Post p) => {
  'id': p.id,
  'worldId': p.worldId,
  'residentId': p.residentId,
  'residentName': p.residentName,
  'residentAvatar': p.residentAvatar,
  'content': p.content,
  'imageUri': p.imageUri,
  'imageUris': p.imageUris,
  'timestamp': p.timestamp,
  'tierAtPosting': p.tierAtPosting.value,
  'reactions': p.reactions,
  'isAnnouncement': p.isAnnouncement,
  'isPinned': p.isPinned,
  'isEdited': p.isEdited,
  'repostOf': p.repostOf,
  'mentions': p.mentions,
  'hashtags': p.hashtags,
  'poll': p.poll?.toJson(),
  'isDecree': p.isDecree,
  'status': p.status,
  'scheduledFor': p.scheduledFor?.toIso8601String(),
  'awards': p.awards,
  'failedPublishes': p.failedPublishes,
  'syncStatus': p.syncStatus.value,
  'localTempId': p.localTempId,
  'syncError': p.syncError,
  'comments': p.comments
      .map(
        (c) => {
          'id': c.id,
          'residentId': c.residentId,
          'residentName': c.residentName,
          'content': c.content,
          'timestamp': c.timestamp,
          'parentId': c.parentId,
          'tierAtPosting': c.tierAtPosting,
        },
      )
      .toList(),
};
