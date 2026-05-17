import '../models/archive.dart';
import 'supabase.dart';

class ArchiveService {
  static Future<List<ArchiveDocument>> getDocuments(
    String worldId, {
    String? category,
    List<String>? tags,
    String? searchQuery,
    int limit = 50,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    var query = client
        .from('archive_documents')
        .select()
        .eq('world_id', worldId)
        .eq('is_published', true);

    if (category != null) {
      query = query.eq('category', category);
    }
    if (tags != null && tags.isNotEmpty) {
      query = query.contains('tags', tags);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.textSearch('title', searchQuery, config: 'english');
    }

    final data = await query
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => ArchiveDocument.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ArchiveDocument?> createDocument({
    required String worldId,
    required String title,
    required String content,
    String category = 'general',
    List<String>? tags,
    List<Map<String, dynamic>>? citations,
  }) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final userId = client.auth.currentUser?.id;
    if (userId == null) return null;

    final result = await client
        .from('archive_documents')
        .insert({
          'world_id': worldId,
          'author_id': userId,
          'title': title,
          'content': content,
          'category': category,
          if (tags != null) 'tags': tags,
          if (citations != null) 'citations': citations,
        })
        .select()
        .single();

    return ArchiveDocument.fromSupabase(result);
  }

  static Future<bool> updateDocument({
    required String id,
    required String title,
    required String content,
    String? category,
    List<String>? tags,
  }) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client
        .from('archive_documents')
        .update({
          'title': title,
          'content': content,
          if (category != null) 'category': category,
          if (tags != null) 'tags': tags,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
    return true;
  }

  static Future<bool> deleteDocument(String id) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client.from('archive_documents').delete().eq('id', id);
    return true;
  }

  static Future<bool> incrementViews(String docId) async {
    if (!isSupabaseConfigured()) return false;
    final client = getSupabase();
    await client.rpc('increment_doc_views', params: {'p_doc_id': docId});
    return true;
  }

  static Future<List<ArchiveCurator>> getCurators(String worldId) async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('archive_curators')
        .select()
        .eq('world_id', worldId)
        .order('appointed_at', ascending: false);
    return (data as List)
        .map((e) => ArchiveCurator.fromSupabase(e as Map<String, dynamic>))
        .toList();
  }
}
