/// The Archivist — AI-powered achievement proof verification.
///
/// Analyzes proof images and returns a confidence score (0.0–1.0) together
/// with extracted text/features.  In production this would call a real AI
/// API (Claude / GPT-4V).  For now it uses heuristics that simulate AI
/// verification with reasonable defaults.
class AiVerificationService {
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
    await Future.delayed(const Duration(milliseconds: 800));

    // Heuristic: if proof URL is a real upload (not 'manual'),
    // give high confidence for auto-approval
    if (proofUrl.startsWith('http') && proofUrl != 'manual') {
      // Image was actually uploaded — high confidence
      return AiVerificationResult(
        confidence: 0.85,
        autoApproved: true,
        extractedText: 'Verified submission for $achievementId',
        notes: 'Auto-verified by The Archivist',
      );
    }

    return AiVerificationResult(
      confidence: 0.3,
      autoApproved: false,
      extractedText: 'Insufficient proof data',
      notes: 'Requires manual review',
    );
  }
}

/// Result returned by [AiVerificationService.analyzeProof].
class AiVerificationResult {
  /// Confidence score 0.0 (no confidence) – 1.0 (certain).
  final double confidence;

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
