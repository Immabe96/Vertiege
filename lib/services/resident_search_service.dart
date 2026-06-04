import 'supabase.dart';

class ResidentSearchHit {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? bioSnippet;

  const ResidentSearchHit({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.bioSnippet,
  });
}

/// Global resident search via Postgres FTS (`search_residents` RPC).
class ResidentSearchService {
  static Future<List<ResidentSearchHit>> search(
    String query, {
    int limit = 20,
  }) async {
    if (!isSupabaseConfigured()) return [];
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      final data = await getSupabase().rpc(
        'search_residents',
        params: {'p_query': trimmed, 'p_limit': limit},
      );
      if (data is! List) return [];
      return data
          .map((row) {
            final m = row as Map<String, dynamic>;
            return ResidentSearchHit(
              id: m['id'] as String,
              name: (m['name'] as String?) ?? 'Resident',
              avatarUrl: m['avatar_url'] as String?,
              bioSnippet: m['bio_snippet'] as String?,
            );
          })
          .toList();
    } catch (_) {
      return [];
    }
  }
}
