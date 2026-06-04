import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/utils/calm_ranking.dart';

void main() {
  group('CalmRanking', () {
    test('leagueBandLabel returns percentile bands', () {
      expect(
        CalmRanking.leagueBandLabel(rank: 1, cohortSize: 100),
        'Top 10% in your league',
      );
      expect(
        CalmRanking.leagueBandLabel(rank: 26, cohortSize: 100),
        'Top 25% in your league',
      );
      expect(
        CalmRanking.leagueBandLabel(rank: 0, cohortSize: 10),
        isNull,
      );
    });

    test('activeResidentsLabel avoids shame copy', () {
      expect(
        CalmRanking.activeResidentsLabel(0),
        'Be among the first residents here',
      );
      expect(
        CalmRanking.activeResidentsLabel(42),
        '42 residents active lately',
      );
    });
  });
}
