import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/achievements.dart';
import '../../models/achievement.dart';
import '../../services/supabase.dart';
import '../../state/achievement_provider.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/glass_panel.dart';

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
    if (_selectedId == null) return;

    setState(() => _isUploading = true);

    String? proofUrl;
    if (_proofImagePath != null) {
      proofUrl = await _uploadToSupabase(_proofImagePath!);
      if (!mounted) return;
    }

    ref.read(achievementProvider.notifier).submitAchievement(
          _selectedId!,
          proofUrl ?? 'manual',
        );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Achievement submitted for verification')),
      );
    }
  }

  Future<String?> _uploadToSupabase(String filePath) async {
    if (!isSupabaseConfigured()) return null;
    final client = getSupabase();
    final ext = filePath.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await client.storage.from('achievement-proofs').upload(
            fileName,
            File(filePath),
          );
      return client.storage.from('achievement-proofs').getPublicUrl(fileName);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achievementNotifier = ref.read(achievementProvider.notifier);
    final visibleAchievements = achievements.where((achievement) {
      return _categoryFilter == null ||
          achievement.category == _categoryFilter;
    }).toList();
    final selectedAchievement = achievements
        .where((achievement) => achievement.id == _selectedId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Submit Achievement')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Spacing.lg,
          Spacing.md,
          Spacing.lg,
          Spacing.xxl,
        ),
        children: [
          GlassPanel(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(RadiusTokens.full),
                    border: Border.all(
                      color: AppColors.tertiary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: AppColors.tertiary,
                    size: IconSizes.lg,
                  ),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit proof',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeights.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        'Pick an unearned achievement, attach proof if needed, and send it for review.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.inkMuted,
                          height: LineHeight.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
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
          const SizedBox(height: Spacing.md),
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
          const SizedBox(height: Spacing.lg),
          GlassPanel(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proof',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeights.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  _proofImagePath != null
                      ? 'This image will be attached to your submission.'
                      : 'Optional, but stronger proof helps reviews move faster.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: Spacing.md),
                if (_proofImagePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(RadiusTokens.full),
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
                      color: AppColors.surfaceElevated.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(RadiusTokens.full),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.inkMuted,
                        size: IconSizes.xl,
                      ),
                    ),
                  ),
                const SizedBox(height: Spacing.md),
                Wrap(
                  spacing: Spacing.sm,
                  runSpacing: Spacing.sm,
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
                        icon: const Icon(Icons.close),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          SizedBox(
            height: TouchTargets.minimum + 6,
            child: FilledButton.icon(
              onPressed:
                  (_selectedId != null && !_isUploading) ? _submit : null,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload),
              label: Text(_isUploading ? 'Uploading...' : 'Submit for Review'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onTertiary,
              ),
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
            padding: const EdgeInsets.only(right: Spacing.sm),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...AchievementCategory.values.map(
            (category) => Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
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
    final categoryColor = _categoryColor(achievement.category);
    final foreground = enabled ? AppColors.ink : AppColors.inkMuted;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        border: Border.all(
          color: selected
              ? categoryColor.withValues(alpha: 0.55)
              : AppColors.glassBorder,
        ),
        child: RadioListTile<String>(
          value: achievement.id,
          enabled: enabled,
          activeColor: categoryColor,
          contentPadding: const EdgeInsets.fromLTRB(
            Spacing.sm,
            Spacing.xs,
            Spacing.md,
            Spacing.xs,
          ),
          secondary: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: enabled ? 0.16 : 0.07),
              borderRadius: BorderRadius.circular(RadiusTokens.full),
            ),
            child: Icon(
              _iconFor(achievement.icon),
              color: enabled ? categoryColor : AppColors.inkMuted,
              size: IconSizes.md,
            ),
          ),
          title: Text(
            achievement.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeights.semiBold,
            ),
          ),
          subtitle: Text(
            '${achievement.xpValue} XP - ${_categoryLabel(achievement.category)}'
            '${enabled ? '' : ' - already submitted'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: enabled
                  ? AppColors.inkMuted
                  : AppColors.inkMuted.withValues(alpha: 0.55),
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
    AchievementCategory.education => AppColors.achievementEducation,
    AchievementCategory.career => AppColors.achievementCareer,
    AchievementCategory.relationships => AppColors.achievementRelationships,
    AchievementCategory.health => AppColors.achievementHealth,
    AchievementCategory.skills => AppColors.achievementSkills,
    AchievementCategory.travel => AppColors.achievementTravel,
    AchievementCategory.finance => AppColors.achievementFinance,
    AchievementCategory.community => AppColors.achievementCommunity,
    AchievementCategory.funny => AppColors.achievementFunny,
    AchievementCategory.creative => AppColors.achievementCreative,
    AchievementCategory.profession => AppColors.achievementProfession,
    AchievementCategory.inApp => AppColors.primary,
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
