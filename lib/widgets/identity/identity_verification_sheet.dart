import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/identity_verification.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/overlays/v_sheet.dart';
import '../../widgets/core/v_feedback.dart';

Future<void> showIdentityVerificationSheet(
  BuildContext context, {
  VoidCallback? onSubmitted,
}) {
  return showVSheet(
    context,
    IdentityVerificationSheet(onSubmitted: onSubmitted),
    maxSize: 0.8,
  );
}

class IdentityVerificationSheet extends ConsumerStatefulWidget {
  final VoidCallback? onSubmitted;

  const IdentityVerificationSheet({super.key, this.onSubmitted});

  @override
  ConsumerState<IdentityVerificationSheet> createState() =>
      _IdentityVerificationSheetState();
}

class _IdentityVerificationSheetState
    extends ConsumerState<IdentityVerificationSheet> {
  IdentityDocumentType _documentType = IdentityDocumentType.passport;
  String? _proofPath;
  bool _submitting = false;
  final _picker = ImagePicker();

  Future<void> _pickProof() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (file != null && mounted) {
      setState(() => _proofPath = file.path);
    }
  }

  Future<void> _submit() async {
    final path = _proofPath;
    if (path == null) {
      VFeedback.showError(context, 'Add a photo of your document.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(residentProvider.notifier).submitIdentityVerification(
            documentType: _documentType,
            proofPath: path,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      VFeedback.showMessage(
        context,
        '${_documentType.label} submitted for review. You\'ll get your tick when approved.',
      );
      widget.onSubmitted?.call();
    } catch (e) {
      if (!mounted) return;
      VFeedback.showError(context, 'Could not submit: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VSpacing.lg,
        VSpacing.md,
        VSpacing.lg,
        VSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verify your identity',
            style: TextStyle(
              fontSize: VFontSize.headlineMd,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimaryOf(brightness),
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'Upload a clear photo of your passport or national identity card. '
            'This is separate from achievement proof.',
            style: TextStyle(
              fontSize: VFontSize.bodySm,
              color: VCommuneColors.textMutedOf(brightness),
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          SegmentedButton<IdentityDocumentType>(
            segments: const [
              ButtonSegment(
                value: IdentityDocumentType.passport,
                label: Text('Passport'),
              ),
              ButtonSegment(
                value: IdentityDocumentType.nationalId,
                label: Text('National ID'),
              ),
            ],
            selected: {_documentType},
            onSelectionChanged: (set) {
              setState(() => _documentType = set.first);
            },
          ),
          const SizedBox(height: VSpacing.md),
          if (_proofPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(VRadius.md),
              child: Image.file(
                File(_proofPath!),
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: _pickProof,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text('Add ${_documentType.label} photo'),
            ),
          const SizedBox(height: VSpacing.lg),
          VButton(
            label: 'Submit for review',
            isFullWidth: true,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
