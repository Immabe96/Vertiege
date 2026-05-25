/// Staff reject reason codes mapped to resident-facing messages.
class AchievementRejectReason {
  final String code;
  final String label;
  final String residentMessage;

  const AchievementRejectReason({
    required this.code,
    required this.label,
    required this.residentMessage,
  });
}

const achievementRejectReasons = [
  AchievementRejectReason(
    code: 'blurry',
    label: 'Photo too blurry',
    residentMessage:
        'Your proof was hard to read. Please resubmit a clearer, well-lit photo.',
  ),
  AchievementRejectReason(
    code: 'wrong_subject',
    label: 'Wrong subject',
    residentMessage:
        'The image did not show what this achievement requires. Please submit proof that matches the description.',
  ),
  AchievementRejectReason(
    code: 'incomplete',
    label: 'Incomplete proof',
    residentMessage:
        'We need more evidence (another angle, date visible, or an extra photo). Please try again.',
  ),
  AchievementRejectReason(
    code: 'not_verifiable',
    label: 'Cannot verify',
    residentMessage:
        'We could not verify this claim from the proof provided. Add stronger evidence or contact support if you disagree.',
  ),
  AchievementRejectReason(
    code: 'duplicate',
    label: 'Duplicate submission',
    residentMessage:
        'This looks like a duplicate of an earlier submission. Submit fresh proof if you are re-applying.',
  ),
  AchievementRejectReason(
    code: 'custom',
    label: 'Other (custom note)',
    residentMessage: '',
  ),
];

AchievementRejectReason? rejectReasonByCode(String? code) {
  if (code == null || code.isEmpty) return null;
  for (final r in achievementRejectReasons) {
    if (r.code == code) return r;
  }
  return null;
}

/// Builds the note stored for the resident (ai_notes / reviewer message).
String buildRejectNote({String? reasonCode, String? customNote}) {
  final trimmed = customNote?.trim() ?? '';
  if (reasonCode == 'custom' || reasonCode == null) {
    return trimmed;
  }
  final preset = rejectReasonByCode(reasonCode);
  if (preset == null) return trimmed;
  if (trimmed.isEmpty) return preset.residentMessage;
  return '${preset.residentMessage}\n\nNote from reviewer: $trimmed';
}
