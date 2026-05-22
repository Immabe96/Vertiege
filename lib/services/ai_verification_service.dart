/// The Archivist — AI-powered achievement proof verification.
///
/// Analyzes proof images and returns a confidence score (0.0–1.0) together
/// with extracted text/features.  In production this would call a real AI
/// API (Claude / GPT-4V).  For now it uses heuristics that simulate AI
/// verification with reasonable defaults.
class AiVerificationService {
  /// When false, all proofs stay in human review (no auto-approve path).
  static const bool autoVerificationEnabled = false;

  /// Analyzes a proof submission and returns an [AiVerificationResult].
  ///
  /// [proofUrl]  – URL of the uploaded proof image, or 'manual' for text-only.
  /// [achievementId] – The achievement being submitted.
  /// [category]   – The achievement category (e.g. 'education', 'career').
  static Future<AiVerificationResult> analyzeProof({
    required String proofUrl,
    required String achievementId,
    required String category,
  }) async {
    // Simulate AI analysis delay (network + inference time)
    // TODO: Replace with real AI moderation (Claude / GPT-4V vision API).
    // Real implementation should analyze the proof image for authenticity,
    // extract relevant text/features, and return a meaningful confidence score.
    // Until then, all submissions require manual review.
    return AiVerificationResult(
      confidence: null,
      autoApproved: false,
      extractedText: '',
      notes: 'Submitted for human review — automated checks are not enabled yet',
    );
  }
}

/// Result returned by [AiVerificationService.analyzeProof].
class AiVerificationResult {
  /// Confidence score 0.0 (no confidence) – 1.0 (certain), or null when
  /// AI verification is unavailable and manual review is required.
  final double? confidence;

  /// Whether this submission qualifies for automatic verification.
  final bool autoApproved;

  /// Text / features extracted from the proof by the AI.
  final String extractedText;

  /// Human-readable notes from the AI verifier.
  final String notes;

  const AiVerificationResult({
    required this.confidence,
    required this.autoApproved,
    required this.extractedText,
    required this.notes,
  });
}
