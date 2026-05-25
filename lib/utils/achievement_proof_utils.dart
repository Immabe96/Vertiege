import 'dart:convert';

/// Parses proof URLs from Supabase row fields.
List<String> parseProofUris({
  String? proofUri,
  dynamic proofUrisRaw,
}) {
  final urls = <String>[];

  if (proofUrisRaw != null) {
    if (proofUrisRaw is List) {
      for (final item in proofUrisRaw) {
        if (item is String && item.isNotEmpty && item != 'manual') {
          urls.add(item);
        }
      }
    } else if (proofUrisRaw is String && proofUrisRaw.startsWith('[')) {
      try {
        final decoded = jsonDecode(proofUrisRaw) as List<dynamic>;
        for (final item in decoded) {
          if (item is String && item.isNotEmpty && item != 'manual') {
            urls.add(item);
          }
        }
      } catch (_) {}
    }
  }

  if (urls.isEmpty &&
      proofUri != null &&
      proofUri.isNotEmpty &&
      proofUri != 'manual' &&
      (proofUri.startsWith('http') || proofUri.startsWith('file'))) {
    urls.add(proofUri);
  }

  return urls;
}

bool isHttpProofUrl(String url) =>
    url.startsWith('http://') || url.startsWith('https://');

List<String> httpProofUrls(Iterable<String> uris) =>
    uris.where(isHttpProofUrl).toList(growable: false);
