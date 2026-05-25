import 'package:flutter_test/flutter_test.dart';
import 'package:vertiege/config/achievement_reject_reasons.dart';
import 'package:vertiege/utils/achievement_reject_feedback.dart';

void main() {
  test('parseRejectFeedback reads code prefix from buildRejectNote', () {
    final note = buildRejectNote(reasonCode: 'blurry', customNote: '');
    final parsed = parseRejectFeedback(note);
    expect(parsed.reasonCode, 'blurry');
    expect(parsed.reasonLabel, 'Photo too blurry');
    expect(parsed.fixSteps, isNotEmpty);
    expect(parsed.message, isNot(contains('[code:')));
  });

  test('parseRejectFeedback infers code from legacy message text', () {
    final preset = achievementRejectReasons.firstWhere((r) => r.code == 'blurry');
    final parsed = parseRejectFeedback(preset.residentMessage);
    expect(parsed.reasonCode, 'blurry');
  });
}
