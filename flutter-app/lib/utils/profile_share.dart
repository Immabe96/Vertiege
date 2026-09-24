/// Deep links and share copy for public resident profiles (Wave 20).
class ProfileShare {
  ProfileShare._();

  static String profilePath(String residentId) =>
      '/residents/${Uri.encodeComponent(residentId)}';

  static Uri profileDeepLink(String residentId) => Uri(
        scheme: 'vertiege',
        host: 'residents',
        pathSegments: [residentId],
      );

  static String shareMessage({
    required String name,
    required String residentId,
    String? achievementId,
  }) {
    final link = profileDeepLink(residentId);
    final query = achievementId != null && achievementId.isNotEmpty
        ? '?achievement=${Uri.encodeComponent(achievementId)}'
        : '';
    return 'View $name on Vertiege\n$link$query';
  }
}
