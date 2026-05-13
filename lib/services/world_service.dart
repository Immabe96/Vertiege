import '../models/channel.dart';
import '../utils/id_generator.dart';
import 'supabase.dart';

class WorldService {
  static bool isRemoteWorldId(String worldId) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(worldId);

  // --- World CRUD ---

  static Future<Map<String, dynamic>?> createWorld({
    required String name,
    required String type,
    required String description,
    required String sovereignId,
    required String sovereignName,
    required String icon,
  }) async {
    final slug = _slugify(name);
    final world = {
      'id': generateId(),
      'slug': slug,
      'name': name,
      'type': type,
      'description': description,
      'sovereign_id': sovereignId,
      'sovereign_name': sovereignName,
      'prestige': 1,
      'icon': icon,
      'is_default': false,
      'sort_order': DateTime.now().millisecondsSinceEpoch,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to create worlds.');
    }

    final client = getSupabase();
    await client.from('worlds').insert(world);
    return world;
  }

  static Future<List<Map<String, dynamic>>> loadWorlds() async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to load worlds.');
    }
    final client = getSupabase();
    final data = await client
        .from('worlds')
        .select()
        .order('sort_order', ascending: true)
        .order('created_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>?> getWorldBySlug(String slug) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('worlds')
        .select()
        .eq('slug', slug)
        .maybeSingle();
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  // --- Membership ---
  static Future<void> joinWorld(
    String worldId,
    String residentId, {
    String residentName = 'Member',
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to join worlds.');
    }
    if (!isRemoteWorldId(worldId)) {
      throw ArgumentError('World id must be a Supabase UUID.');
    }
    final client = getSupabase();
    await client.from('world_members').upsert({
      'world_id': worldId,
      'resident_id': residentId,
      'resident_name': residentName,
      'rep': 0,
      'joined_at': DateTime.now().toIso8601String(),
    }, onConflict: 'world_id, resident_id');
  }

  static Future<void> leaveWorld(String worldId, String residentId) async {
    if (!isSupabaseConfigured() || !isRemoteWorldId(worldId)) return;
    final client = getSupabase();
    await client
        .from('world_members')
        .delete()
        .eq('world_id', worldId)
        .eq('resident_id', residentId);
  }

  static Future<List<Map<String, dynamic>>> getMembers(String worldId) async {
    if (!isSupabaseConfigured() || !isRemoteWorldId(worldId)) return [];
    final client = getSupabase();
    final data = await client
        .from('world_members')
        .select()
        .eq('world_id', worldId)
        .order('rep', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<List<WorldChannel>> getChannels(String worldId) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to load channels.');
    }
    if (!isRemoteWorldId(worldId)) return [];
    final client = getSupabase();
    final data = await client
        .from('channels')
        .select()
        .eq('world_id', worldId)
        .order('position', ascending: true);
    return (data as List)
        .map((e) => WorldChannel.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> createChannel(WorldChannel channel) async {
    if (!isSupabaseConfigured() || !isRemoteWorldId(channel.worldId)) return;
    final client = getSupabase();
    await client.from('channels').insert(channel.toSupabase());
  }

  static Future<void> renameChannel(String channelId, String newName) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase()
        .from('channels')
        .update({'name': newName})
        .eq('id', channelId);
  }

  static Future<void> deleteChannel(String channelId) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase()
        .from('channels')
        .delete()
        .eq('id', channelId)
        .eq('is_default', false);
  }

  static Future<List<WorldChannel>> createDefaultChannels(
    String worldId,
  ) async {
    if (!isSupabaseConfigured() || !isRemoteWorldId(worldId)) return [];
    final existing = await getChannels(worldId);
    final existingNames = existing.map((c) => c.name.toLowerCase()).toSet();
    final created = <WorldChannel>[];
    final nextPosition = existing.isEmpty
        ? 0
        : existing
                  .map((c) => c.position)
                  .fold<int>(
                    0,
                    (max, position) => position > max ? position : max,
                  ) +
              1;

    const defaults = [
      (
        'info',
        'Start here for the world purpose, culture, and key links.',
        ChannelType.announcement,
      ),
      (
        'rules',
        'The standards, boundaries, and moderation expectations.',
        ChannelType.announcement,
      ),
      (
        'roles',
        'Rank, role, and permission guidance for residents.',
        ChannelType.announcement,
      ),
      ('general', 'General discussion for all residents.', ChannelType.text),
    ];

    for (var i = 0; i < defaults.length; i++) {
      final (name, desc, type) = defaults[i];
      if (existingNames.contains(name)) continue;
      final channel = WorldChannel(
        id: generateId(),
        worldId: worldId,
        name: name,
        description: desc,
        channelType: type,
        position: nextPosition + created.length,
        isDefault: true,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      created.add(channel);
      try {
        await createChannel(channel);
      } catch (_) {
        created.removeLast();
        break;
      }
    }
    return [...existing, ...created]
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  static String _slugify(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'world-${generateId().substring(0, 8)}' : slug;
  }
}
