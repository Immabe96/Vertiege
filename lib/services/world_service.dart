import 'package:flutter/foundation.dart';
import '../models/channel.dart';
import '../models/world.dart';
import '../utils/id_generator.dart';
import '../utils/presence_utils.dart';
import '../widgets/core/status_dot.dart' as v_status;
import '../utils/validators.dart' as validators;
import '../utils/world_foundations.dart';
import 'supabase.dart';
import 'crash_reporter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorldService {
  /// Client-only pseudo-worlds (e.g. Nexus feed) — never synced to `world_members`.
  static const Set<String> localOnlyWorldIds = {'nexus'};

  /// True when [worldId] refers to a row in Supabase `worlds` (UUID or slug pk).
  static bool isRemoteWorldId(String worldId) {
    if (localOnlyWorldIds.contains(worldId)) return false;
    if (validators.isUuid(worldId)) return true;
    // Seeded worlds use slug ids (e.g. neon-district, aetheria, crystal-shore).
    return RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$').hasMatch(worldId);
  }

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
      // Postgres `sort_order` is INT; ms since epoch overflows (22003).
      'sort_order': DateTime.now().millisecondsSinceEpoch ~/ 1000,
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
    final result = await client.rpc(
      'create_world_full',
      params: {
        'p_name': name,
        'p_description': description,
        'p_sovereign_id': sovereignId,
        'p_sovereign_name': sovereignName,
        'p_icon': icon,
        if (dominionType != null && dominionType.isNotEmpty)
          'p_dominion_type': dominionType,
        if (worldCurrencyName != null && worldCurrencyName.isNotEmpty)
          'p_world_currency_name': worldCurrencyName,
        if (tags != null && tags.isNotEmpty) 'p_tags': tags,
      },
    );
    if (result is Map) {
      final createdWorld = Map<String, dynamic>.from(result);
      final worldId = createdWorld['id']?.toString();
      if (worldId != null && worldId.isNotEmpty) {
        try {
          await createDefaultChannels(worldId);
        } catch (e, st) {
          CrashReporter.instance.recordError(
            e,
            st,
            hint: 'world_service post-create gated channel creation',
          );
        }
      }
      return createdWorld;
    }
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
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to update worlds.');
    }
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
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to delete worlds.');
    }
    final client = getSupabase();
    await client.from('worlds').delete().eq('id', worldId);
    return true;
  }

  static Future<World?> getWorld(String worldId) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('worlds')
        .select()
        .eq('id', worldId)
        .maybeSingle();
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

  static Future<List<Map<String, dynamic>>> getTrendingWorlds({
    int limit = 10,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('worlds')
        .select()
        .order('activity_score', ascending: false)
        .limit(limit);
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getFeaturedWorlds({
    int limit = 5,
  }) async {
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
        'WorldService: Supabase not configured, returning empty worlds list (offline mode)',
      );
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
    final data = await client
        .from('worlds')
        .select()
        .eq('slug', slug)
        .maybeSingle();
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  // --- Membership ---
  static Future<void> joinWorlds(
    List<String> worldIds,
    String residentId, {
    String residentName = 'Member',
  }) async {
    if (worldIds.isEmpty) return;
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to join worlds.');
    }
    final client = getSupabase();
    final now = DateTime.now().toIso8601String();
    try {
      final rows = worldIds
          .map(
            (worldId) => {
              'world_id': worldId,
              'resident_id': residentId,
              'resident_name': residentName,
              'rep': 0,
              'joined_at': now,
            },
          )
          .toList();
      await client.from('world_members').insert(rows);
      for (final worldId in worldIds) {
        await client.rpc('increment_world_members', params: {'w_id': worldId});
      }
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // Fall back to sequential insertion if a batch fails on duplicate keys
        for (final worldId in worldIds) {
          await joinWorld(worldId, residentId, residentName: residentName);
        }
      } else {
        rethrow;
      }
    }
  }

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
      try {
        await client.rpc(
          'claim_world_sovereignty_if_unclaimed',
          params: {'p_world_id': worldId},
        );
      } catch (e, st) {
        CrashReporter.instance.recordError(
          e,
          st,
          hint: 'claim_world_sovereignty_if_unclaimed',
        );
      }
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

  static Future<List<Map<String, dynamic>>> getMembers(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    try {
      final data = await client
          .from('world_members')
          .select(
            '*, profiles(avatar_url, tier, total_xp, last_seen_at, verified_roles, presence_mode, custom_status, avatar_frame_id)',
          )
          .eq('world_id', worldId)
          .order('rep', ascending: false);
      return (data as List)
          .cast<Map<String, dynamic>>()
          .map(_flattenMemberProfile)
          .toList();
    } catch (_) {
      final data = await client
          .from('world_members')
          .select()
          .eq('world_id', worldId)
          .order('rep', ascending: false);
      return (data as List).cast<Map<String, dynamic>>();
    }
  }

  static Map<String, dynamic> _flattenMemberProfile(Map<String, dynamic> row) {
    final profile = row['profiles'];
    if (profile is! Map<String, dynamic>) return row;
    return {
      ...row,
      'avatar_url': profile['avatar_url'],
      'tier': profile['tier'],
      'total_xp': profile['total_xp'],
      'last_seen_at': profile['last_seen_at'],
      'verified_roles': profile['verified_roles'],
      'presence_mode': profile['presence_mode'],
      'custom_status': profile['custom_status'],
      'avatar_frame_id': profile['avatar_frame_id'],
    };
  }

  /// Recently active residents for world activity preview (Wave S5).
  static Future<List<Map<String, dynamic>>> getActiveResidents(
    String worldId, {
    int limit = 5,
  }) async {
    if (!isSupabaseConfigured()) return [];
    try {
      final data = await getSupabase().rpc(
        'list_world_active_residents',
        params: {'p_world_id': worldId, 'p_limit': limit},
      );
      return (data as List).cast<Map<String, dynamic>>();
    } catch (_) {
      final counts = await residentPresenceCounts(worldId);
      if (counts.online == 0) return [];
      final members = await getMembers(worldId);
      return members
          .where(
            (m) =>
                presenceFromProfileField(m['last_seen_at']) ==
                v_status.Presence.online,
          )
          .take(limit)
          .map(
            (m) => {
              'resident_id': m['resident_id'],
              'resident_name': m['resident_name'],
              'avatar_url': m['avatar_url'],
            },
          )
          .toList();
    }
  }

  /// Total + online residents for world headers (profiles.last_seen_at when available).
  static Future<({int total, int online})> residentPresenceCounts(
    String worldId,
  ) async {
    if (!isSupabaseConfigured()) return (total: 0, online: 0);
    try {
      final client = getSupabase();
      final data = await client
          .from('world_members')
          .select('resident_id, profiles(last_seen_at)')
          .eq('world_id', worldId);
      final rows = (data as List).cast<Map<String, dynamic>>();
      var online = 0;
      for (final row in rows) {
        final profile = row['profiles'];
        final lastSeen = profile is Map<String, dynamic>
            ? profile['last_seen_at']
            : null;
        if (presenceFromProfileField(lastSeen) == v_status.Presence.online) {
          online++;
        }
      }
      return (total: rows.length, online: online);
    } catch (_) {
      final members = await getMembers(worldId);
      return (total: members.length, online: 0);
    }
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
    String worldId, {
    World? world,
  }) async {
    if (!isSupabaseConfigured()) return [];
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
      (
        'lounge',
        'A high-standing resident lounge for trusted world conversation.',
        ChannelType.text,
      ),
      (
        'campfire',
        'Live voice for eligible lounge residents once audio rooms unlock.',
        ChannelType.voice,
      ),
    ];

    for (var i = 0; i < defaults.length; i++) {
      final (name, desc, type) = defaults[i];
      if (existingNames.contains(name)) continue;

      String foundationMarkdown = '';
      if (world != null &&
          (name == 'info' || name == 'rules' || name == 'roles')) {
        foundationMarkdown = foundationMarkdownForChannel(
          world: world,
          channelName: name,
        );
      }

      final channel = WorldChannel(
        id: generateId(),
        worldId: worldId,
        name: name,
        description: desc,
        channelType: type,
        position: nextPosition + created.length,
        isDefault: true,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        foundationMarkdown: foundationMarkdown,
      );
      created.add(channel);
      try {
        await createChannel(channel);
      } catch (e, st) {
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

  /// Persists dominion [activity_score] via server RPC (no-op when offline).
  static Future<void> bumpActivityScore(String worldId, int delta) async {
    if (!isSupabaseConfigured() || !isRemoteWorldId(worldId) || delta == 0) {
      return;
    }
    try {
      await getSupabase().rpc(
        'bump_world_activity_score',
        params: {'p_world_id': worldId, 'p_delta': delta},
      );
    } catch (e, st) {
      debugPrint('WorldService.bumpActivityScore error: $e');
      CrashReporter.instance.recordError(
        e,
        st,
        hint: 'bump_world_activity_score',
      );
    }
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
