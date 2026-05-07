import '../models/channel.dart';
import '../utils/id_generator.dart';
import 'supabase.dart';

class WorldService {
  // --- World CRUD ---

  static Future<Map<String, dynamic>?> createWorld({
    required String name,
    required String type,
    required String description,
    required String sovereignId,
    required String sovereignName,
    required String icon,
  }) async {
    final world = {
      'id': generateId(),
      'name': name,
      'type': type,
      'description': description,
      'sovereign_id': sovereignId,
      'sovereign_name': sovereignName,
      'prestige': 1,
      'icon': icon,
      'created_at': DateTime.now().toIso8601String(),
    };

    if (!isSupabaseConfigured()) return world;

    final client = getSupabase();
    await client.from('worlds').insert(world);
    return world;
  }

  static Future<List<Map<String, dynamic>>> loadWorlds() async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('worlds')
        .select()
        .order('created_at', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  // --- Membership ---
  static Future<void> joinWorld(String worldId, String residentId, {String residentName = 'Member'}) async {
    if (!isSupabaseConfigured()) return;
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
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client
        .from('world_members')
        .delete()
        .eq('world_id', worldId)
        .eq('resident_id', residentId);
  }

  static Future<List<Map<String, dynamic>>> getMembers(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('world_members')
        .select()
        .eq('world_id', worldId)
        .order('rep', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<List<WorldChannel>> getChannels(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('channels')
        .select()
        .eq('world_id', worldId)
        .order('position', ascending: true);
    return (data as List).map((e) => WorldChannel.fromSupabase(e)).toList();
  }

  static Future<void> createChannel(WorldChannel channel) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('channels').insert(channel.toSupabase());
  }

  static Future<List<WorldChannel>> createDefaultChannels(String worldId) async {
    const defaults = [
      ('general', 'General discussion', ChannelType.text),
      ('lounge', 'Off-topic and casual chat', ChannelType.text),
      ('introductions', 'New residents introduce themselves', ChannelType.text),
    ];

    final channels = <WorldChannel>[];
    for (var i = 0; i < defaults.length; i++) {
      final (name, desc, type) = defaults[i];
      final channel = WorldChannel(
        id: generateId(),
        worldId: worldId,
        name: name,
        description: desc,
        channelType: type,
        position: i,
        isDefault: true,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
      channels.add(channel);
      await createChannel(channel);
    }
    return channels;
  }
}
