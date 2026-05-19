import 'dart:io';
import '../utils/id_generator.dart';
import 'supabase.dart';

class VerificationSubmission {
  final String id;
  final String residentId;
  final String residentName;
  final String profession;
  final String proofUrl;
  final String status; // pending, approved, rejected
  final String? reviewerNotes;
  final int createdAt;

  const VerificationSubmission({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.profession,
    required this.proofUrl,
    required this.status,
    this.reviewerNotes,
    required this.createdAt,
  });

  static VerificationSubmission fromSupabase(Map<String, dynamic> data) =>
      VerificationSubmission(
        id: data['id'] ?? '',
        residentId: data['resident_id'] ?? '',
        residentName: data['resident_name'] ?? '',
        profession: data['profession'] ?? '',
        proofUrl: data['proof_url'] ?? '',
        status: data['status'] ?? 'pending',
        reviewerNotes: data['reviewer_notes'],
        createdAt:
            DateTime.tryParse(
              data['created_at'] ?? '',
            )?.millisecondsSinceEpoch ??
            0,
      );
}

class VerificationService {
  static const _bucket = 'verification-proofs';

  static const _allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];
  static const _maxFileSize = 10 * 1024 * 1024; // 10MB

  /// Upload a proof file to Supabase Storage. Returns the public URL.
  /// Validates file extension and size before upload.
  static Future<String?> uploadProof(String filePath, String residentId) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to upload verification proofs.');
    }

    final ext = filePath.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw ArgumentError('Invalid file type. Allowed: $_allowedExtensions');
    }

    final file = File(filePath);
    final fileSize = await file.length();
    if (fileSize > _maxFileSize) {
      throw ArgumentError('File too large. Maximum size: 10MB');
    }

    final client = getSupabase();
    final fileName =
        '${residentId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await client.storage.from(_bucket).upload(fileName, file);
    return await client.storage
        .from(_bucket)
        .createSignedUrl(fileName, 365 * 24 * 60 * 60);
  }

  /// Submit a verification request for admin review.
  static Future<void> submitVerification({
    required String residentId,
    required String residentName,
    required String profession,
    required String proofUrl,
  }) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to submit verification.');
    }
    final client = getSupabase();
    await client.from('verification_submissions').insert({
      'id': generateId(),
      'resident_id': residentId,
      'resident_name': residentName,
      'profession': profession,
      'proof_url': proofUrl,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get all pending verification submissions for admin review.
  static Future<List<VerificationSubmission>> getPending() async {
    if (!isSupabaseConfigured()) return [];
    final client = getSupabase();
    final data = await client
        .from('verification_submissions')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (data as List)
        .map(
          (e) => VerificationSubmission.fromSupabase(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get a resident's latest verification status.
  static Future<String?> getVerificationStatus(
    String residentId,
    String profession,
  ) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final data = await client
        .from('verification_submissions')
        .select('status')
        .eq('resident_id', residentId)
        .eq('profession', profession)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data?['status'] as String?;
  }

  /// Approve a verification submission.
  static Future<void> approve(
    String submissionId,
    String residentId,
    String profession,
  ) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to approve verifications.');
    }
    final client = getSupabase();
    await client
        .from('verification_submissions')
        .update({'status': 'verified'})
        .eq('id', submissionId);
  }

  /// Reject a verification submission.
  static Future<void> reject(String submissionId, {String? notes}) async {
    if (!isSupabaseConfigured()) {
      throw StateError('Supabase is required to reject verifications.');
    }
    final client = getSupabase();
    await client
        .from('verification_submissions')
        .update({'status': 'rejected', 'reviewer_notes': notes})
        .eq('id', submissionId);
  }
}
