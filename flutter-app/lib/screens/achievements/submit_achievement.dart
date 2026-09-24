import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/achievements.dart';
import 'package:vertiege/ui/ui.dart';
import '../../models/achievement.dart';
import '../../services/achievement_proof_upload.dart';
import '../../state/achievement_provider.dart';
import '../../theme/prestige_noir.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/achievements/achievement_icon.dart';
import '../../widgets/achievements/proof_requirements_banner.dart';
import '../../widgets/achievements/ai_proof_preview_panel.dart';
import '../../widgets/core/empty_state.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();
  bool _isUploading = false;
  AchievementCategory? _categoryFilter;
  String? _errorText;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  void _selectAchievement(String? id) {
    if (id == _selectedId) return;
    setState(() {
      _selectedId = id;
      _proofImagePaths.clear();
      _errorText = null;
    });
  }

  void _selectCategory(AchievementCategory? category) {
    setState(() {
      _categoryFilter = category;
      if (_selectedId != null) {
        final selected = achievements
            .where((a) => a.id == _selectedId)
            .firstOrNull;
        if (category != null && selected?.category != category) {
          _selectAchievement(null);
        }
      }
    });
  }

  int _earnedInCategory(
    AchievementCategory category,
    AchievementNotifier notifier,
  ) {
    return achievements
        .where(
          (a) =>
              a.category == category &&
              notifier.getAchievementStatus(a.id) ==
                  AchievementStatus.verified,
        )
        .length;
  }

  Future<void> _pickProofImages() async {
    final ach = achievements.where((a) => a.id == _selectedId).firstOrNull;
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
      _errorText = null;
    });
  }

  void _removeProofAt(int index) {
    setState(() {
      _proofImagePaths.removeAt(index);
      _errorText = null;
    });
  }

  Future<void> _submit() async {
    final selectedId = _selectedId;
    if (selectedId == null) {
      setState(() => _errorText = 'Choose an achievement first.');
      return;
    }
    final ach = achievementForId(selectedId)!;
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
              achievementId: selectedId,
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
          .submitAchievement(
            selectedId,
            proofUrls,
            story: _storyController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        VFeedback.showMessage(
          context,
          'Submitted — a verifier will review your proof soon.',
        );
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

  List<Achievement> _visibleAchievements(AchievementNotifier notifier) {
    final q = _searchQuery.trim().toLowerCase();
    return achievements.where((achievement) {
      if (_categoryFilter != null && achievement.category != _categoryFilter) {
        return false;
      }
      if (notifier.getAchievementStatus(achievement.id) !=
          AchievementStatus.locked) {
        return false;
      }
      if (q.isEmpty) return true;
      return achievement.title.toLowerCase().contains(q) ||
          achievement.description.toLowerCase().contains(q) ||
          achievement.id.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achievementNotifier = ref.read(achievementProvider.notifier);
    final visibleAchievements = _visibleAchievements(achievementNotifier);
    final selectedAchievement = achievements
        .where((achievement) => achievement.id == _selectedId)
        .firstOrNull;
    final canSubmit = _selectedId != null && !_isUploading;
    final categories = AchievementCategory.values
        .where((c) => c != AchievementCategory.inApp)
        .toList();

    return VHubPage(
      title: 'Submit Achievement',
      showBack: true,
      footer: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: VButton(
          label: _isUploading ? 'Uploading…' : 'Submit for Verification',
          isFullWidth: true,
          isLoading: _isUploading,
          icon: const Icon(VIcons.upload, size: 18),
          onPressed: canSubmit ? _submit : null,
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
          _SectionLabel(label: 'Category'),
          const SizedBox(height: VSpacing.xs),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.35,
            children: [
              for (final category in categories)
                _CategoryOption(
                  label: categoryDisplayName(category),
                  icon: metaForCategory(category).icon,
                  earnedCount: _earnedInCategory(category, achievementNotifier),
                  selected: _categoryFilter == category,
                  onTap: () => _selectCategory(
                    _categoryFilter == category ? null : category,
                  ),
                ),
            ],
          ),
          const SizedBox(height: VSpacing.lg),
          _SectionLabel(label: 'Achievement'),
          const SizedBox(height: VSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
            decoration: BoxDecoration(
              color: PrestigeNoir.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: PrestigeNoir.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: PrestigeNoir.muted),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: PrestigeNoir.foreground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search or type a new achievement name...',
                      hintStyle: TextStyle(color: PrestigeNoir.mutedDim),
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: PrestigeNoir.muted,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.md),
          if (visibleAchievements.isEmpty)
            AppEmptyState(
              title: _searchQuery.isNotEmpty
                  ? 'No matches'
                  : 'Nothing to submit here',
              description: _searchQuery.isNotEmpty
                  ? 'Try another search or clear the category filter.'
                  : 'Achievements you already submitted appear under '
                        'Achievements with a pending or verified status.',
              icon: Icons.emoji_events_outlined,
            )
          else
            RadioGroup<String>(
              groupValue: _selectedId,
              onChanged: _selectAchievement,
              child: Column(
                children: visibleAchievements.map((achievement) {
                  final meta = metaForCategory(achievement.category);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: VSpacing.xs),
                    child: VTile(
                      onPress: () => _selectAchievement(achievement.id),
                      prefix: AchievementBadgeAvatar(
                        achievement: achievement,
                        accentColor: meta.color,
                      ),
                      title: Text(achievement.title),
                      subtitle: Text(
                        '${achievement.xpValue} XP · ${meta.label}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      suffix: Radio<String>(value: achievement.id),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (selectedAchievement != null) ...[
            const SizedBox(height: VSpacing.lg),
            _SectionLabel(label: 'Description'),
            const SizedBox(height: VSpacing.xs),
            TextField(
              controller: _storyController,
              maxLines: 4,
              maxLength: 280,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: PrestigeNoir.foreground,
              ),
              decoration: InputDecoration(
                hintText: 'Describe what you accomplished...',
                hintStyle: TextStyle(color: PrestigeNoir.mutedDim),
                filled: true,
                fillColor: PrestigeNoir.surfaceRaised,
                contentPadding: const EdgeInsets.all(VSpacing.md),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: PrestigeNoir.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: PrestigeNoir.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: VColors.brand),
                ),
              ),
            ),
            const SizedBox(height: VSpacing.md),
            ProofRequirementsBanner(achievement: selectedAchievement),
            const SizedBox(height: VSpacing.md),
            AiProofPreviewPanel(
              achievement: selectedAchievement,
              proofImageCount: _proofImagePaths.length,
              storyText: _storyController.text,
            ),
            const SizedBox(height: VSpacing.md),
            _SectionLabel(label: 'Proof'),
            const SizedBox(height: VSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: _ProofUploadCard(
                    icon: Icons.photo_camera_outlined,
                    label: 'Screenshot',
                    uploaded: _proofImagePaths.isNotEmpty,
                    previewPath: _proofImagePaths.isNotEmpty
                        ? _proofImagePaths.first
                        : null,
                    onTap: _proofImagePaths.length >=
                            selectedAchievement.effectiveMaxImages
                        ? null
                        : _pickProofImages,
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: _ProofUploadCard(
                    icon: Icons.description_outlined,
                    label: 'Document',
                    uploaded: false,
                    onTap: _pickProofImages,
                  ),
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: _ProofUploadCard(
                    icon: Icons.link,
                    label: 'Link',
                    uploaded: false,
                    onTap: null,
                  ),
                ),
              ],
            ),
            if (_proofImagePaths.length > 1) ...[
              const SizedBox(height: VSpacing.sm),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _proofImagePaths.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: VSpacing.sm),
                  itemBuilder: (_, i) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(VRadius.md),
                        child: Image.file(
                          File(_proofImagePaths[i]),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Material(
                          color: VColors.error,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _removeProofAt(i),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: VIconSize.sm,
                                color: VColors.onError,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (_proofImagePaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: VSpacing.sm),
                child: Text(
                  'Photos (${_proofImagePaths.length}/${selectedAchievement.effectiveMaxImages})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: PrestigeNoir.muted,
                  ),
                ),
              ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: VSpacing.md),
            VCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: VColors.error),
                  const SizedBox(width: VSpacing.sm),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: VColors.error,
                        fontWeight: VFontWeight.semiBold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: PrestigeNoir.muted,
        fontWeight: VFontWeight.semiBold,
        letterSpacing: 0.6,
        fontSize: 12,
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final int earnedCount;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.label,
    required this.icon,
    required this.earnedCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? PrestigeNoir.accentSoft : PrestigeNoir.surfaceRaised,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? VColors.brand : PrestigeNoir.borderLight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? VColors.brand : PrestigeNoir.foreground,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: VFontWeight.semiBold,
                  color: PrestigeNoir.foreground,
                ),
              ),
              Text(
                '$earnedCount earned',
                style: TextStyle(
                  fontSize: 10,
                  color: PrestigeNoir.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofUploadCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool uploaded;
  final String? previewPath;
  final VoidCallback? onTap;

  const _ProofUploadCard({
    required this.icon,
    required this.label,
    required this.uploaded,
    this.previewPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Material(
        color: uploaded
            ? VColors.success.withValues(alpha: 0.08)
            : PrestigeNoir.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: uploaded ? VColors.success : PrestigeNoir.border,
              ),
            ),
            child: previewPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(previewPath!), fit: BoxFit.cover),
                        if (uploaded)
                          Container(
                            color: VColors.success.withValues(alpha: 0.25),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.check,
                              color: VColors.success,
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        uploaded ? Icons.check : icon,
                        size: uploaded ? 20 : 24,
                        color: uploaded ? VColors.success : PrestigeNoir.muted,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        uploaded ? 'Uploaded' : label,
                        style: TextStyle(
                          fontSize: 12,
                          color: uploaded
                              ? VColors.success
                              : PrestigeNoir.muted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
