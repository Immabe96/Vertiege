import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/achievements.dart';
import '../../models/achievement.dart';
import '../../services/supabase.dart';
import '../../state/achievement_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/icons/v_icons.dart';

class SubmitAchievementScreen extends ConsumerStatefulWidget {
  const SubmitAchievementScreen({super.key});

  @override
  ConsumerState<SubmitAchievementScreen> createState() =>
      _SubmitAchievementScreenState();
}

class _SubmitAchievementScreenState
    extends ConsumerState<SubmitAchievementScreen> {
  String? _selectedId;
  String? _proofImagePath;
  bool _isUploading = false;
  AchievementCategory? _categoryFilter;
  String? _errorText;

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (!mounted) return;
    if (result != null) {
      setState(() => _proofImagePath = result.path);
    }
  }

  Future<void> _submit() async {
    if (_selectedId == null) {
      setState(() => _errorText = 'Choose an achievement first.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorText = null;
    });

    try {
      String proofUrl = 'manual';
      if (_proofImagePath != null) {
        final uploaded = await _uploadToSupabase(_proofImagePath!);
        if (!mounted) return;
        if (uploaded == null) {
          setState(() {
            _isUploading = false;
            _errorText =
                'Proof upload failed. Please try again or remove the image.';
          });
          return;
        }
        proofUrl = uploaded;
      }

      await ref
          .read(achievementProvider.notifier)
          .submitAchievement(_selectedId!, proofUrl);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Achievement submitted for verification'),
            behavior: SnackBarBehavior.floating,
          ),
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

  Future<String?> _uploadToSupabase(String filePath) async {
    if (!isSupabaseConfigured()) return null;
    final userId = maybeSupabase()?.auth.currentUser?.id;
    final achievementId = _selectedId;
    if (userId == null || achievementId == null) return null;
    final client = getSupabase();
    final ext = filePath.split('.').last.toLowerCase();
    final fileName =
        '$userId/$achievementId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await client.storage
          .from('achievement-proofs')
          .upload(fileName, File(filePath));
      final urlResult = await client.storage
          .from('achievement-proofs')
          .createSignedUrl(fileName, 365 * 24 * 60 * 60);
      return urlResult;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final achievementNotifier = ref.read(achievementProvider.notifier);
    final visibleAchievements = achievements.where((achievement) {
      return _categoryFilter == null || achievement.category == _categoryFilter;
    }).toList();
    final selectedAchievement = achievements
        .where((achievement) => achievement.id == _selectedId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Submit Achievement',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: VFontWeight.semiBold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpacing.lg,
          VSpacing.md,
          VSpacing.lg,
          VSpacing.xxl,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(VSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.xl),
              border: Border.all(
                color: isDark
                    ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                    : VColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: VColors.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(VRadius.pill),
                    border: Border.all(
                      color: VColors.tertiary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: VColors.tertiary,
                    size: VIconSize.lg,
                  ),
                ),
                const SizedBox(width: VSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit proof',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: VFontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: VSpacing.xs),
                      Text(
                        'Choose an achievement and attach proof when it helps the review.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          _CategoryRail(
            selected: _categoryFilter,
            onSelected: (category) {
              setState(() {
                _categoryFilter = category;
                if (_selectedId != null &&
                    category != null &&
                    selectedAchievement?.category != category) {
                  _selectedId = null;
                }
              });
            },
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
                return _AchievementOption(
                  achievement: achievement,
                  enabled: status == AchievementStatus.locked,
                  selected: _selectedId == achievement.id,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          Container(
            padding: const EdgeInsets.all(VSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? VColors.surfaceContainerDark
                  : VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.xl),
              border: Border.all(
                color: isDark
                    ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                    : VColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proof',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
                const SizedBox(height: VSpacing.xs),
                Text(
                  _proofImagePath != null
                      ? 'This image will be attached to your submission.'
                      : 'Optional, but stronger proof helps reviews move faster.',
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
                      height: 176,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 132,
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
                Wrap(
                  spacing: VSpacing.sm,
                  runSpacing: VSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickProofImage,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(
                        _proofImagePath != null ? 'Change Image' : 'Add Image',
                      ),
                    ),
                    if (_proofImagePath != null)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _proofImagePath = null),
                        icon: const Icon(VIcons.x),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: VColors.error,
                          side: BorderSide(
                            color: VColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpacing.lg),
          if (_errorText != null) ...[
            Text(
              _errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: VColors.error,
                fontWeight: VFontWeight.semiBold,
              ),
            ),
            const SizedBox(height: VSpacing.sm),
          ],
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: (_selectedId != null && !_isUploading)
                  ? _submit
                  : null,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(VIcons.upload),
              label: Text(_isUploading ? 'Uploading...' : 'Submit for Review'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRail extends StatelessWidget {
  final AchievementCategory? selected;
  final ValueChanged<AchievementCategory?> onSelected;

  const _CategoryRail({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: VSpacing.sm),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...AchievementCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: VSpacing.sm),
              child: ChoiceChip(
                label: Text(_categoryLabel(category)),
                selected: selected == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementOption extends StatelessWidget {
  final Achievement achievement;
  final bool enabled;
  final bool selected;

  const _AchievementOption({
    required this.achievement,
    required this.enabled,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryColor = _categoryColor(achievement.category);
    final foreground = enabled
        ? (isDark ? VColors.onSurfaceDark : VColors.onSurface)
        : (isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? VColors.surfaceContainerDark
              : VColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(VRadius.xl),
          border: Border.all(
            color: selected
                ? categoryColor.withValues(alpha: 0.55)
                : (isDark
                    ? VColors.outlineVariantDark.withValues(alpha: 0.2)
                    : VColors.outlineVariant.withValues(alpha: 0.3)),
          ),
        ),
        child: RadioListTile<String>(
          value: achievement.id,
          enabled: enabled,
          activeColor: categoryColor,
          contentPadding: const EdgeInsets.fromLTRB(
            VSpacing.sm,
            VSpacing.xs,
            VSpacing.md,
            VSpacing.xs,
          ),
          secondary: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: enabled ? 0.16 : 0.07),
              borderRadius: BorderRadius.circular(VRadius.pill),
            ),
            child: Icon(
              _iconFor(achievement.icon),
              color: enabled
                  ? categoryColor
                  : (isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant),
              size: VIconSize.md,
            ),
          ),
          title: Text(
            achievement.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: foreground,
              fontWeight: VFontWeight.semiBold,
            ),
          ),
          subtitle: Text(
            '${achievement.xpValue} XP - ${_categoryLabel(achievement.category)}'
            '${enabled ? '' : ' - already submitted'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: enabled
                  ? (isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant)
                  : (isDark
                      ? VColors.onSurfaceVariantDark.withValues(alpha: 0.55)
                      : VColors.onSurfaceVariant.withValues(alpha: 0.55)),
            ),
          ),
        ),
      ),
    );
  }
}

String _categoryLabel(AchievementCategory category) {
  return switch (category) {
    AchievementCategory.inApp => 'In App',
    _ => '${category.name[0].toUpperCase()}${category.name.substring(1)}',
  };
}

Color _categoryColor(AchievementCategory category) {
  return switch (category) {
    AchievementCategory.education => VColors.achievementEducation,
    AchievementCategory.career => VColors.achievementCareer,
    AchievementCategory.relationships => VColors.achievementSocial,
    AchievementCategory.health => VColors.achievementHealth,
    AchievementCategory.skills => VColors.achievementCreative,
    AchievementCategory.travel => VColors.achievementAdventure,
    AchievementCategory.finance => VColors.achievementFinance,
    AchievementCategory.community => VColors.achievementLeadership,
    AchievementCategory.funny => VColors.tertiary,
    AchievementCategory.creative => VColors.achievementCreative,
    AchievementCategory.profession => VColors.primary,
    AchievementCategory.inApp => VColors.primary,
  };
}

IconData _iconFor(String name) {
  return switch (name) {
    'school' => Icons.school_outlined,
    'translate' => Icons.translate,
    'verified' => Icons.verified_outlined,
    'work' => Icons.work_outline,
    'trending_up' => Icons.trending_up,
    'swap_horiz' => Icons.swap_horiz,
    'store' => Icons.storefront_outlined,
    'corporate_fare' => Icons.corporate_fare,
    'payments' => Icons.payments_outlined,
    'home_work' => Icons.home_work_outlined,
    'beach_access' => Icons.beach_access_outlined,
    'favorite' => Icons.favorite_border,
    'ring_volume' => Icons.diamond_outlined,
    'home' => Icons.home_outlined,
    'child_care' => Icons.child_care_outlined,
    'people' => Icons.people_outline,
    'directions_run' => Icons.directions_run,
    'monitor_weight' => Icons.monitor_weight_outlined,
    'fitness_center' => Icons.fitness_center,
    'pool' => Icons.pool,
    'directions_bike' => Icons.directions_bike,
    'block' => Icons.block,
    'self_improvement' => Icons.self_improvement,
    'code' => Icons.code,
    'music_note' => Icons.music_note,
    'restaurant' => Icons.restaurant_outlined,
    'directions_car' => Icons.directions_car_outlined,
    'surfing' => Icons.surfing,
    'mic' => Icons.mic_none,
    'construction' => Icons.construction,
    'flight' => Icons.flight,
    'flight_takeoff' => Icons.flight_takeoff,
    'public' => Icons.public,
    'language' => Icons.language,
    'star' => Icons.star_border,
    'savings' => Icons.savings_outlined,
    'shield' => Icons.shield_outlined,
    'check_circle' => Icons.check_circle_outline,
    'volunteer_activism' => Icons.volunteer_activism_outlined,
    'bloodtype' => Icons.bloodtype_outlined,
    'diversity_3' => Icons.diversity_3,
    'forest' => Icons.forest_outlined,
    'event' => Icons.event_outlined,
    'nightlight' => Icons.nightlight_outlined,
    'groups' => Icons.groups_outlined,
    'local_pizza' => Icons.local_pizza_outlined,
    'toys' => Icons.toys_outlined,
    'pets' => Icons.pets,
    'phone_in_talk' => Icons.phone_in_talk_outlined,
    'tv' => Icons.tv,
    'question_mark' => Icons.question_mark,
    'chair' => Icons.chair_outlined,
    'menu_book' => Icons.menu_book_outlined,
    'palette' => Icons.palette_outlined,
    'lyrics' => Icons.lyrics_outlined,
    'play_circle' => Icons.play_circle_outline,
    'theater_comedy' => Icons.theater_comedy_outlined,
    'edit_note' => Icons.edit_note,
    'record_voice_over' => Icons.record_voice_over_outlined,
    'history_edu' => Icons.history_edu,
    'auto_stories' => Icons.auto_stories_outlined,
    'explore' => Icons.explore_outlined,
    'hiking' => Icons.hiking,
    'terrain' => Icons.terrain,
    'local_fire_department' => Icons.local_fire_department_outlined,
    _ => Icons.workspace_premium_outlined,
  };
}
