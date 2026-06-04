import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/models/season_cohort.dart';

void main() {
  test('SeasonCohortSummary parses RPC cohort payload', () {
    final cohort = SeasonCohortSummary.fromJson({
      'id': 'c1',
      'season_id': 'season_1',
      'world_id': 'w1',
      'display_name': 'Aurora cohort',
      'member_count': 12,
    });
    expect(cohort.displayName, 'Aurora cohort');
    expect(cohort.memberCount, 12);
  });

  test('SeasonCohortSummary parses optional match band', () {
    final cohort = SeasonCohortSummary.fromJson({
      'id': 'c1',
      'season_id': 'season_1',
      'world_id': 'w1',
      'display_name': 'Aurora cohort',
      'member_count': 3,
      'match_band': 'established',
    });
    expect(cohort.matchBand, 'established');
  });
}
