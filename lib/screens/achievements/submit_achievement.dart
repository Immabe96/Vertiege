import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../config/achievements.dart';
import '../../forui/v_hub_page.dart';
import '../../models/achievement.dart';
import '../../services/achievement_proof_upload.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/achievements/achievement_icon.dart';
import '../../widgets/achievements/proof_requirements_banner.dart';
import '../../widgets/core/v_feedback.dart';

class SubmitAchievementScreen extends ConsumerStatefulWidget {
  const SubmitAchievementScreen({super.key});

  @override
  ConsumerState<SubmitAchievementScreen> createState() =>
      _SubmitAchievementScreenState();
}

class _SubmitAchievementScreenState
    extends ConsumerState<SubmitAchievementScreen> {
  String? _selectedId;
  final List<String> _proofImagePaths = [];
  bool _isUploading = false;
  AchievementCategory? _categoryFilter;
  String? _errorText;

  Future<void> _pickProofImages() async {
    final ach = achievements
        .where((a) => a.id == _selectedId)
        .firstOrNull;
    if (ach == null) return;
    final max = ach.effectiveMaxImages - _proofImagePaths.length;
    if (max <= 0) return;
    final paths = await AchievementProofUpload.pickGalleryImages(limit: max);
    if (!mounted || paths.isEmpty) return;
    setState(() {
      _proofImagePaths.addAll(paths);
      if (_proofImagePaths.length > ach.effectiveMaxImages) {
        _proofImagePaths.removeRange(
          ach.effectiveMaxImages,
          _proofImagePaths.length,
        );
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedId == null) {
      setState(() => _errorText = 'Choose an achievement first.');
      return;
    }
    final ach = achievementForId(_selectedId)!;
    final min = ach.effectiveMinImages;
    if (min > 0 && _proofImagePaths.length < min) {
      setState(() {
        _errorText = 'Add at least $min photo${min > 1 ? 's' : ''}.';
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
              achievementId: _selectedId!,
              filePaths: _proofImagePaths,
            );
      if (!mounted) return;
      if (_proofImagePaths.isNotEmpty && proofUrls.isEmpty) {
        setState(() {
          _isUploading = false;
          _errorText = 'Proof upload failed. Try again.';
        });
        return;
      }

      await ref
          .read(achievementProvider.notifier)
          .submitAchievement(_selectedId!, proofUrls);

      if (mounted) {
        Navigator.pop(context);
        VFeedback.showMessage(context, 'Achievement submitted for verification');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorText =
            'Submission failed. Please check your connection and retry.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final achievementNotifier = ref.read(achievementProvider.notifier);
    final visibleAchievements = achievements.where((achievement) {
      return _categoryFilter == null ||
          achievement.category == _categoryFilter;
    }).toList();
    final selectedAchievement = achievements
        .where((achievement) => achievement.id == _selectedId)
        .firstOrNull;

    return VHubPage(
      title: 'Submit proof',
      showBack: true,
      footer: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: FButton(
          onPress: (_selectedId != null && !_isUploading) ? _submit : null,
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
              Text(_isUploading ? 'Uploading…' : 'Submit for review'),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.md,
          VSpacing.md,
          VSpacing.md,
          VSpacing.xxl,
        ),
        children: [
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(VSpacing.md),
              child: Text(
                'Pick an achievement and attach photo proof when it helps verification.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: VSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: VSpacing.sm),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: _categoryFilter == null,
                    onSelected: (_) => setState(() {
                      _categoryFilter = null;
                      _selectedId = null;
                    }),
                  ),
                ),
                for (final category in AchievementCategory.values)
                  if (category != AchievementCategory.inApp)
                    Padding(
                      padding: const EdgeInsets.only(right: VSpacing.sm),
                      child: FilterChip(
                        label: Text(categoryDisplayName(category)),
                        selected: _categoryFilter == category,
                        onSelected: (_) => setState(() {
                          _categoryFilter = category;
                          if (_selectedId != null &&
                              selectedAchievement?.category != category) {
                            _selectedId = null;
                          }
                        }),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.md),
          RadioGroup<String>(
            groupValue: _selectedId,
            onChanged: (value) => setState(() => _selectedId = value),
            child: Column(
              children: visibleAchievements.map((achievement) {
                final status = achievementNotifier.getAchievementStatus(
                  achievement.id,
                );
                final enabled = status == AchievementStatus.locked;
                final meta = metaForCategory(achievement.category);
                return Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.xs),
                  child: FTile(
                    enabled: enabled,
                    onPress: enabled
                        ? () => setState(() => _selectedId = achievement.id)
                        : null,
                    prefix: AchievementBadgeAvatar(
                      achievement: achievement,
                      accentColor: meta.color,
                      size: VBadgeSize.avatar,
                    ),
                    title: Text(achievement.title),
                    subtitle: Text(
                      '${achievement.xpValue} XP · ${meta.label}'
                      '${enabled ? '' : ' · already submitted'}',
                    ),
                    suffix: Radio<String>(
                      value: achievement.id,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (selectedAchievement != null) ...[
            const SizedBox(height: VSpacing.lg),
            ProofRequirementsBanner(achievement: selectedAchievement),
            const SizedBox(height: VSpacing.md),
            if (_proofImagePaths.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _proofImagePaths.length,
                  separatorBuilder: (_, _) => const SizedBox(width: VSpacing.sm),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(VRadius.lg),
                    child: Image.file(
                      File(_proofImagePaths[i]),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: _selectedId == null ||
                      _proofImagePaths.length >=
                          selectedAchievement.effectiveMaxImages
                  ? null
                  : _pickProofImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _proofImagePaths.isEmpty
                    ? 'Add photos'
                    : 'Photos (${_proofImagePaths.length}/${selectedAchievement.effectiveMaxImages})',
              ),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: VSpacing.md),
            Text(
              _errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: VColors.error,
                fontWeight: VFontWeight.semiBold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
