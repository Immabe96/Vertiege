import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/achievements.dart';
import '../../models/achievement.dart';
import '../../services/profile_service.dart';
import '../../state/achievement_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/achievements/achievement_icon.dart';
import '../../widgets/core/v_feedback.dart';

/// Pick up to 3 verified achievements for the public profile (Wave 20).
void showFeaturedAchievementsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _FeaturedAchievementsSheet(),
  );
}

class _FeaturedAchievementsSheet extends ConsumerStatefulWidget {
  const _FeaturedAchievementsSheet();

  @override
  ConsumerState<_FeaturedAchievementsSheet> createState() =>
      _FeaturedAchievementsSheetState();
}

class _FeaturedAchievementsSheetState
    extends ConsumerState<_FeaturedAchievementsSheet> {
  List<String> _selected = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) {
      setState(() => _loading = false);
      return;
    }
    final ids = await ProfileService.getFeaturedAchievementIds(resident.id);
    if (mounted) {
      setState(() {
        _selected = ids;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ProfileService.setFeaturedAchievements(_selected);
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
      VFeedback.showMessage(context, 'Featured achievements updated.');
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected = _selected.where((x) => x != id).toList();
      } else if (_selected.length < 3) {
        _selected = [..._selected, id];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verified = ref
        .watch(achievementProvider)
        .userAchievements
        .where((a) => a.status == AchievementStatus.verified)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: VSpacing.lg,
        right: VSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + VSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Featured achievements',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: VFontWeight.bold,
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'Choose up to 3 verified achievements to highlight on your public profile.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: VSpacing.md),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(VSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (verified.isEmpty)
            const Text('Verify achievements first to feature them.')
          else
            SizedBox(
              height: 280,
              child: ListView.builder(
                itemCount: verified.length,
                itemBuilder: (_, i) {
                  final ua = verified[i];
                  final def = achievementForId(ua.achievementId);
                  if (def == null) return const SizedBox.shrink();
                  final picked = _selected.contains(ua.achievementId);
                  final disabled =
                      !picked && _selected.length >= 3;
                  return CheckboxListTile(
                    value: picked,
                    onChanged: disabled
                        ? null
                        : (_) => _toggle(ua.achievementId),
                    secondary: AchievementBadgeAvatar(
                      achievement: def,
                      accentColor: VColors.tertiary,
                      size: VBadgeSize.avatarCompact,
                    ),
                    title: Text(def.title),
                    subtitle: Text(def.category.name),
                  );
                },
              ),
            ),
          const SizedBox(height: VSpacing.md),
          FilledButton(
            onPressed: _saving || _loading ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save featured (${_selected.length}/3)'),
          ),
        ],
      ),
    );
  }
}
