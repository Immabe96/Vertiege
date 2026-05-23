import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../models/achievement.dart';
import '../../services/achievement_proof_upload.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import 'achievement_icon.dart';

/// Bottom sheet: achievement detail, proof upload, submit.
Future<void> showAchievementProofSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Achievement achievement,
  required AchievementStatus status,
  UserAchievement? userAchievement,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AchievementProofSheet(
      achievement: achievement,
      status: status,
      userAchievement: userAchievement,
    ),
  );
}

class _AchievementProofSheet extends ConsumerStatefulWidget {
  final Achievement achievement;
  final AchievementStatus status;
  final UserAchievement? userAchievement;

  const _AchievementProofSheet({
    required this.achievement,
    required this.status,
    this.userAchievement,
  });

  @override
  ConsumerState<_AchievementProofSheet> createState() =>
      _AchievementProofSheetState();
}

class _AchievementProofSheetState extends ConsumerState<_AchievementProofSheet> {
  String? _proofImagePath;
  bool _isUploading = false;
  String? _errorText;

  bool get _canSubmit =>
      widget.status == AchievementStatus.locked ||
      widget.status == AchievementStatus.rejected;

  Future<void> _pickImage() async {
    final path = await AchievementProofUpload.pickGalleryImage();
    if (!mounted || path == null) return;
    setState(() => _proofImagePath = path);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isUploading = true;
      _errorText = null;
    });

    try {
      var proofUrl = 'manual';
      if (_proofImagePath != null) {
        final uploaded = await AchievementProofUpload.uploadProofFile(
          achievementId: widget.achievement.id,
          filePath: _proofImagePath!,
        );
        if (!mounted) return;
        if (uploaded == null) {
          setState(() {
            _isUploading = false;
            _errorText =
                'Proof upload failed. Try again or submit without an image.';
          });
          return;
        }
        proofUrl = uploaded;
      }

      await ref
          .read(achievementProvider.notifier)
          .submitAchievement(widget.achievement.id, proofUrl);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Achievement submitted for verification'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorText = 'Submission failed. Check your connection and retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = statusColor(widget.status);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) {
          return Material(
            color: isDark ? VColors.surfaceDark : VColors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VRadius.xl),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                VSpacing.lg,
                VSpacing.md,
                VSpacing.lg,
                VSpacing.xxl,
              ),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? VColors.outlineVariantDark
                          : VColors.outlineVariant,
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: VSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AchievementBadgeAvatar(
                      achievement: widget.achievement,
                      accentColor: accent,
                      size: 52,
                    ),
                    const SizedBox(width: VSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.achievement.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: VFontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: VSpacing.xs),
                          Text(
                            widget.achievement.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? VColors.onSurfaceVariantDark
                                  : VColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: VSpacing.sm),
                          Row(
                            children: [
                              _StatusPill(
                                label: statusLabel(widget.status),
                                color: accent,
                              ),
                              const SizedBox(width: VSpacing.sm),
                              Text(
                                '+${widget.achievement.xpValue} XP',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: VColors.warning,
                                  fontWeight: VFontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.status == AchievementStatus.verified) ...[
                  const SizedBox(height: VSpacing.lg),
                  FCard.raw(
                    child: Padding(
                      padding: const EdgeInsets.all(VSpacing.md),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: VColors.success,
                          ),
                          const SizedBox(width: VSpacing.sm),
                          Expanded(
                            child: Text(
                              'This achievement is verified on your profile.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (widget.status == AchievementStatus.submitted) ...[
                  const SizedBox(height: VSpacing.lg),
                  FCard.raw(
                    child: Padding(
                      padding: const EdgeInsets.all(VSpacing.md),
                      child: Text(
                        widget.userAchievement?.aiNotes?.isNotEmpty == true
                            ? widget.userAchievement!.aiNotes!
                            : 'Your proof is in review. You will earn XP once verified.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
                if (_canSubmit) ...[
                  const SizedBox(height: VSpacing.lg),
                  Text(
                    'Photo proof',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: VFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    'Optional but recommended — helps reviews approve faster.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: VSpacing.md),
                  if (_proofImagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(VRadius.xl),
                      child: Image.file(
                        File(_proofImagePath!),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? VColors.surfaceContainerHighDark
                            : VColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(VRadius.xl),
                        border: Border.all(
                          color: isDark
                              ? VColors.outlineVariantDark
                              : VColors.outlineVariant,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: VColors.onSurfaceVariant,
                          size: VIconSize.xl,
                        ),
                      ),
                    ),
                  const SizedBox(height: VSpacing.md),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _pickImage,
                        child: Text(
                          _proofImagePath != null ? 'Change photo' : 'Add photo',
                        ),
                      ),
                      if (_proofImagePath != null) ...[
                        const SizedBox(width: VSpacing.sm),
                        OutlinedButton(
                          onPressed: () => setState(() => _proofImagePath = null),
                          child: const Text('Remove'),
                        ),
                      ],
                    ],
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: VSpacing.sm),
                    Text(
                      _errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: VColors.error,
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                  ],
                  const SizedBox(height: VSpacing.lg),
                  FButton(
                    onPress: _isUploading ? null : _submit,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isUploading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(VIcons.upload, size: 18),
                        const SizedBox(width: VSpacing.sm),
                        Text(
                          _isUploading
                              ? 'Submitting…'
                              : 'Submit for review',
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: VFontSize.labelSm,
          fontWeight: VFontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
