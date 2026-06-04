import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/router/progress_navigation.dart';

void main() {
  test('progressPath builds hub URLs', () {
    expect(progressPath(), '/progress');
    expect(progressPath(tab: ProgressTab.quests), '/progress?tab=quests');
    expect(progressPath(tab: ProgressTab.league), '/progress?tab=league');
  });

  test('ProgressTab.fromQuery parses tab param', () {
    expect(ProgressTab.fromQuery('world'), ProgressTab.world);
    expect(ProgressTab.fromQuery('invalid'), isNull);
  });
}
