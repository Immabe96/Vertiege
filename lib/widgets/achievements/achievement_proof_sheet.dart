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
import 'achievement_resubmit_banner.dart';
import 'proof_requirements_banner.dart';
import '../../widgets/core/v_feedback.dart';

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
  final List<String> _proofImagePaths = [];
  bool _isUploading = false;
  String? _errorText;

  bool get _canSubmit =>
      widget.status == AchievementStatus.locked ||
      widget.status == AchievementStatus.rejected;

  Achievement get _ach => widget.achievement;

  Future<void> _pickImages() async {
    final max = _ach.effectiveMaxImages - _proofImagePaths.length;
    if (max <= 0) return;
    final paths = await AchievementProofUpload.pickGalleryImages(limit: max);
    if (!mounted || paths.isEmpty) return;
    setState(() {
      _proofImagePaths.addAll(paths);
      if (_proofImagePaths.length > _ach.effectiveMaxImages) {
        _proofImagePaths.removeRange(
          _ach.effectiveMaxImages,
          _proofImagePaths.length,
        );
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final min = _ach.effectiveMinImages;
    if (min > 0 && _proofImagePaths.length < min) {
      setState(() {
        _errorText = 'Add at least $min photo${min > 1 ? 's' : ''} for this achievement.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorText = null;
    });

    try {
      final proofUrls = _proofImagePaths.isEmpty
          ? <String>[]
          : await AchievementProofUpload.uploadProofFiles(
              achievementId: _ach.id,
              filePaths: _proofImagePaths,
            );
      if (!mounted) return;
      if (_proofImagePaths.isNotEmpty && proofUrls.isEmpty) {
        setState(() {
          _isUploading = false;
          _errorText =
              'Proof upload failed. Try again or submit without images if allowed.';
        });
        return;
      }
      if (min > 0 && proofUrls.length < min) {
        setState(() {
          _isUploading = false;
          _errorText = 'Upload at least $min photo${min > 1 ? 's' : ''}.';
        });
        return;
      }

      await ref
          .read(achievementProvider.notifier)
          .submitAchievement(_ach.id, proofUrls);

      if (!mounted) return;
      Navigator.pop(context);
      VFeedback.showMessage(
        context,
        widget.status == AchievementStatus.rejected
            ? 'Resubmitted for review — we will notify you when verified'
            : 'Achievement submitted for verification',
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
    final profileVisible = ref
            .watch(achievementProvider)
            .userAchievements
            .where((a) => a.achievementId == widget.achievement.id)
            .map((a) => a.isProfileVisible)
            .firstOrNull ??
        widget.userAchievement?.isProfileVisible ??
        true;

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
                      size: VBadgeSize.avatarSheet,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: VColors.success,
                              ),
                              const SizedBox(width: VSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Verified — XP counted toward your tier.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: VSpacing.md),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Show on public profile'),
                            subtitle: Text(
                              profileVisible
                                  ? 'Other residents can see this badge.'
                                  : 'Hidden from your profile wall.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                            value: profileVisible,
                            onChanged: (visible) {
                              ref
                                  .read(achievementProvider.notifier)
                                  .setAchievementProfileVisibility(
                                    achievementId: widget.achievement.id,
                                    visible: visible,
                                  );
                            },
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
                        'Your proof is in the manual review queue. You will earn XP once a verifier approves it.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
                if (widget.status == AchievementStatus.rejected) ...[
                  const SizedBox(height: VSpacing.lg),
                  AchievementResubmitBanner(
                    reviewerNotes: widget.userAchievement?.aiNotes,
                  ),
                ],
                if (_canSubmit) ...[
                  const SizedBox(height: VSpacing.lg),
                  ProofRequirementsBanner(achievement: _ach),
                  const SizedBox(height: VSpacing.md),
                  if (_proofImagePaths.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _proofImagePaths.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: VSpacing.sm),
                        itemBuilder: (_, i) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(VRadius.lg),
                              child: Image.file(
                                File(_proofImagePaths[i]),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Material(
                                color: Colors.black54,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _proofImagePaths.removeAt(i),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 100,
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
                  OutlinedButton.icon(
                    onPressed: _proofImagePaths.length >= _ach.effectiveMaxImages
                        ? null
                        : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      _proofImagePaths.isEmpty
                          ? 'Add photos'
                          : 'Add more (${_proofImagePaths.length}/${_ach.effectiveMaxImages})',
                    ),
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
