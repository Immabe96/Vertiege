import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../models/world.dart';
import '../utils/id_generator.dart';
import '../utils/validators.dart' as validators;
import 'supabase.dart';
import 'crash_reporter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorldService {
  static bool isRemoteWorldId(String worldId) => validators.isUuid(worldId);

  // --- World CRUD ---

  static Future<Map<String, dynamic>?> createWorld({
    required String name,
    required String type,
    required String description,
    required String sovereignId,
    required String sovereignName,
    required String icon,
    String? motto,
    String? accentColor,
    String? lore,
    String? dominionType,
    String? worldCurrencyName,
    int taxRate = 0,
    Map<String, dynamic>? constitution,
    List<String>? tags,
    String? welcomeMessage,
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
      'created_at': DateTime.now().toIso8601String(),
      if (motto != null && motto.isNotEmpty) 'motto': motto,
      if (accentColor != null && accentColor.isNotEmpty)
        'accent_color': accentColor,
      if (lore != null && lore.isNotEmpty) 'lore': lore,
      if (dominionType != null && dominionType.isNotEmpty)
        'dominion_type': dominionType,
      if (worldCurrencyName != null && worldCurrencyName.isNotEmpty)
        'world_currency_name': worldCurrencyName,
      'tax_rate': taxRate,
      if (constitution != null) 'constitution': constitution,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (welcomeMessage != null && welcomeMessage.isNotEmpty)
        'welcome_message': welcomeMessage,
    };

    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to create worlds.');
    }

    final client = getSupabase();
    await client.from('worlds').insert(world);
    return world;
  }

  static Future<bool> updateWorld({
    required String worldId,
    String? name,
    String? description,
    String? icon,
    String? motto,
    String? accentColor,
    String? lore,
    Map<String, dynamic>? constitution,
    List<String>? tags,
    String? worldCurrencyName,
    int? taxRate,
    String? welcomeMessage,
  }) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (icon != null) updates['icon'] = icon;
    if (motto != null) updates['motto'] = motto;
    if (accentColor != null) updates['accent_color'] = accentColor;
    if (lore != null) updates['lore'] = lore;
    if (constitution != null) updates['constitution'] = constitution;
    if (tags != null) updates['tags'] = tags;
    if (worldCurrencyName != null)
      updates['world_currency_name'] = worldCurrencyName;
    if (taxRate != null) updates['tax_rate'] = taxRate;
    if (welcomeMessage != null) updates['welcome_message'] = welcomeMessage;

    if (updates.isEmpty) return true;
    await client.from('worlds').update(updates).eq('id', worldId);
    return true;
  }

  static Future<bool> deleteWorld(String worldId) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client.from('worlds').delete().eq('id', worldId);
    return true;
  }

  static Future<World?> getWorld(String worldId) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data =
        await client.from('worlds').select().eq('id', worldId).maybeSingle();
    if (data == null) return null;
    return World.fromSupabase(data);
  }

  static Future<List<Map<String, dynamic>>> searchWorlds({
    String? query,
    String? type,
    String? dominionType,
    List<String>? tags,
    int minPrestige = 0,
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    var q = client.from('worlds').select();

    if (type != null) q = q.eq('type', type);
    if (dominionType != null) q = q.eq('dominion_type', dominionType);
    if (minPrestige > 0) q = q.gte('prestige', minPrestige);
    if (tags != null && tags.isNotEmpty) q = q.contains('tags', tags);
    if (query != null && query.isNotEmpty) {
      q = q.or('name.ilike.*$query*,description.ilike.*$query*');
    }

    final data = await q
        .order('prestige', ascending: false)
        .order('member_count', ascending: false)
        .limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getTrendingWorlds(
      {int limit = 10}) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('worlds')
        .select()
        .order('activity_score', ascending: false)
        .limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getFeaturedWorlds(
      {int limit = 5}) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('worlds')
        .select()
        .gte('prestige', 20)
        .order('prestige', ascending: false)
        .limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> loadWorlds() async {
    if (!isSupabaseConfigured()) {
      debugPrint(
          'WorldService: Supabase not configured, returning empty worlds list (offline mode)');
      return [];
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
    final data =
        await client.from('worlds').select().eq('slug', slug).maybeSingle();
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
    final client = getSupabase();
    try {
      await client.from('world_members').insert({
        'world_id': worldId,
        'resident_id': residentId,
        'resident_name': residentName,
        'rep': 0,
        'joined_at': DateTime.now().toIso8601String(),
      });
      await client.rpc('increment_world_members', params: {'w_id': worldId});
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      rethrow;
    }
  }

  static Future<void> leaveWorld(String worldId, String residentId) async {
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client
        .from('world_members')
        .delete()
        .eq('world_id', worldId)
        .eq('resident_id', residentId);
    await client.rpc('decrement_world_members', params: {'w_id': worldId});
  }

  static Future<List<Map<String, dynamic>>> getMembersForWorlds(
      List<String> worldIds) async {
    if (!isSupabaseConfigured() || worldIds.isEmpty) return [];
    final client = getSupabase();
    final data = await client
        .from('world_members')
        .select()
        .inFilter('world_id', worldIds)
        .order('rep', ascending: false);
    return (data as List).cast<Map<String, dynamic>>();
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
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to load channels.');
    }
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
    if (!isSupabaseConfigured()) return;
    final client = getSupabase();
    await client.from('channels').insert(channel.toSupabase());
  }

  static Future<void> renameChannel(String channelId, String newName) async {
    if (!isSupabaseConfigured()) return;
    await getSupabase()
        .from('channels')
        .update({'name': newName}).eq('id', channelId);
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
    if (!isSupabaseConfigured()) return [];
    final existing = await getChannels(worldId);
    final existingNames = existing.map((c) => c.name.toLowerCase()).toSet();
    final created = <WorldChannel>[];
    final nextPosition = existing.isEmpty
        ? 0
        : existing.map((c) => c.position).fold<int>(
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
      } catch (e, st) {
        // Expected failure for duplicate channels — roll back and stop.
        // Logged for diagnostics in case of unexpected errors.
        CrashReporter.instance.recordError(
          e,
          st,
          hint: 'world_service default channel creation',
        );
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

  // --- Prestige ---
  static Future<List<Map<String, dynamic>>> getHighPrestigeWorlds(
    String residentId,
  ) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    try {
      final data = await client
          .from('world_members')
          .select('worlds(name, prestige)')
          .eq('resident_id', residentId)
          .gte('worlds.prestige', 30);
      final results = <Map<String, dynamic>>[];
      for (final row in data as List) {
        final worldData = row['worlds'] as Map<String, dynamic>?;
        if (worldData != null) {
          results.add({
            'name': worldData['name'] as String? ?? 'Unknown',
            'prestige': (worldData['prestige'] as int?) ?? 0,
          });
        }
      }
      return results;
    } catch (e) {
      debugPrint('WorldService.getHighPrestigeWorlds error: $e');
      return [];
    }
  }
}
