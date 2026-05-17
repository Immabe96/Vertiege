class Rank {
  final String id;
  final String worldId;
  final String name;
  final String colorHex;
  final bool isHoisted;
  final bool isMentionable;
  final int position;
  final Map<String, bool> edicts;

  const Rank({
    required this.id,
    required this.worldId,
    required this.name,
    this.colorHex = '#CFBCFF',
    this.isHoisted = false,
    this.isMentionable = false,
    this.position = 0,
    this.edicts = const {
      'canPost': true,
      'canComment': true,
      'canInvite': false,
      'canModerate': false,
      'canManage': false,
      'canPin': false,
      'canDelete': false,
      'canKick': false,
      'canBan': false,
    },
  });

  factory Rank.fromSupabase(Map<String, dynamic> data) {
    Map<String, bool> edicts = {};
    final rawEdicts = data['edicts'];
    if (rawEdicts is Map) {
      for (final entry in rawEdicts.entries) {
        edicts[entry.key.toString()] = entry.value == true;
      }
    }
    return Rank(
      id: data['id'] ?? '',
      worldId: data['world_id'] ?? '',
      name: data['name'] ?? '',
      colorHex: data['color'] ?? '#CFBCFF',
      isHoisted: data['is_hoisted'] ?? false,
      isMentionable: data['is_mentionable'] ?? false,
      position: data['position'] ?? 0,
      edicts: edicts,
    );
  }

  Map<String, dynamic> toSupabase() => {
    'id': id,
    'world_id': worldId,
    'name': name,
    'color': colorHex,
    'is_hoisted': isHoisted,
    'is_mentionable': isMentionable,
    'position': position,
    'edicts': edicts,
  };
}
