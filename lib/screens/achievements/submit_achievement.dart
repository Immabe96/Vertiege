import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/achievements.dart';
import 'package:vertiege/ui/ui.dart';
import '../../models/achievement.dart';
import '../../services/achievement_proof_upload.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/achievements/achievement_icon.dart';
import '../../widgets/achievements/proof_requirements_banner.dart';
import '../../widgets/core/empty_state.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark
        ? VColors.onSurfaceVariantDark
        : VColors.onSurfaceVariant;
    final achievementNotifier = ref.read(achievementProvider.notifier);
    final visibleAchievements = _visibleAchievements(achievementNotifier);
    final selectedAchievement = achievements
        .where((achievement) => achievement.id == _selectedId)
        .firstOrNull;
    final canSubmit = _selectedId != null && !_isUploading;

    return VHubPage(
      title: 'Submit proof',
      showBack: true,
      footer: Padding(
        padding: const EdgeInsets.all(VSpacing.md),
        child: VButton(
          label: _isUploading ? 'Uploading…' : 'Submit for review',
          isFullWidth: true,
          isLoading: _isUploading,
          icon: Icon(VIcons.upload, size: 18),
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
          VSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: VColors.primary,
                        size: VIconSize.md,
                      ),
                      const SizedBox(width: VSpacing.sm),
                      Text(
                        'Manual verification',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: VFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpacing.xs),
                  Text(
                    'Choose an achievement, add clear photos when required, '
                    'and a human verifier will approve or request more proof.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
          ),
          const SizedBox(height: VSpacing.md),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search achievements…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.lg),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
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
                      _selectAchievement(null);
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
                            _selectAchievement(null);
                          }
                        }),
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
                        size: VBadgeSize.avatar,
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
            Text(
              selectedAchievement.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
            if (selectedAchievement.description.isNotEmpty) ...[
              const SizedBox(height: VSpacing.xs),
              Text(
                selectedAchievement.description,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
            if (selectedAchievement.proofHint != null &&
                selectedAchievement.proofHint!.trim().isNotEmpty) ...[
              const SizedBox(height: VSpacing.sm),
              Text(
                selectedAchievement.proofHint!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: VColors.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: VSpacing.md),
            TextField(
              controller: _storyController,
              maxLines: 3,
              maxLength: 280,
              decoration: const InputDecoration(
                labelText: 'Your story (optional)',
                hintText: 'A short note for your profile if approved',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: VSpacing.md),
            ProofRequirementsBanner(achievement: selectedAchievement),
            const SizedBox(height: VSpacing.md),
            if (_proofImagePaths.isNotEmpty)
              SizedBox(
                height: 128,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _proofImagePaths.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: VSpacing.sm),
                  itemBuilder: (_, i) => Stack(
                    clipBehavior: Clip.none,
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
                                size: 16,
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
            const SizedBox(height: VSpacing.sm),
            OutlinedButton.icon(
              onPressed:
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
            VSurfaceCard(
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
