import '../config/achievement_reject_reasons.dart';

/// Parsed staff rejection for resident resubmit UI.
class ParsedRejectFeedback {
  final String? reasonCode;
  final String reasonLabel;
  final String message;
  final List<String> fixSteps;

  const ParsedRejectFeedback({
    this.reasonCode,
    required this.reasonLabel,
    required this.message,
    required this.fixSteps,
  });
}

final _codePrefix = RegExp(r'^\[code:([a-z_]+)\]');

/// Extracts reason code and resident-facing text from stored [ai_notes].
ParsedRejectFeedback parseRejectFeedback(String? rawNotes) {
  final raw = rawNotes?.trim() ?? '';
  if (raw.isEmpty) {
    return ParsedRejectFeedback(
      reasonLabel: 'Needs changes',
      message: 'Your proof was not approved. Add stronger evidence and resubmit.',
      fixSteps: resubmitStepsForCode(null),
    );
  }

  var code = _codePrefix.firstMatch(raw)?.group(1);
  var message = raw;
  if (code != null) {
    message = raw.replaceFirst(_codePrefix, '').trim();
  } else {
    code = _inferCodeFromMessage(message);
  }

  final preset = rejectReasonByCode(code);
  return ParsedRejectFeedback(
    reasonCode: code,
    reasonLabel: preset?.label ?? 'Needs changes',
    message: message.isEmpty ? (preset?.residentMessage ?? raw) : message,
    fixSteps: resubmitStepsForCode(code),
  );
}

String? _inferCodeFromMessage(String message) {
  for (final reason in achievementRejectReasons) {
    if (reason.code == 'custom') continue;
    if (reason.residentMessage.isNotEmpty &&
        message.contains(reason.residentMessage)) {
      return reason.code;
    }
  }
  return null;
}

/// Short line for list tiles.
String rejectSummaryForList(String? rawNotes) {
  final parsed = parseRejectFeedback(rawNotes);
  if (parsed.message.length <= 72) return parsed.message;
  return '${parsed.message.substring(0, 69)}…';
}
