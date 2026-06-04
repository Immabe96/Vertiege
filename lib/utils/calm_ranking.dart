/// Calm competition copy (Wave 16) — percentile bands instead of shame framing.
class CalmRanking {
  CalmRanking._();

  /// Returns a friendly band like "Top 25% in your league" when [cohortSize] > 0.
  static String? leagueBandLabel({
    required int rank,
    required int cohortSize,
  }) {
    if (rank <= 0 || cohortSize <= 0) return null;
    final percentile = ((cohortSize - rank + 1) / cohortSize * 100).ceil().clamp(
      1,
      100,
    );
    if (percentile >= 90) return 'Top 10% in your league';
    if (percentile >= 75) return 'Top 25% in your league';
    if (percentile >= 50) return 'Top half of your league';
    return 'Building momentum in your league';
  }

  /// Social proof without dark patterns.
  static String activeResidentsLabel(int count) {
    if (count <= 0) return 'Be among the first residents here';
    if (count == 1) return '1 resident active lately';
    return '$count residents active lately';
  }
}
