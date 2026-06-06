import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/achievements.dart' as ach_config;
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_commune_colors.dart';
import '../../theme/v_tokens.dart';
import '../../ui/buttons/v_button.dart';
import '../../ui/overlays/v_sheet.dart';
import '../../widgets/achievements/achievement_category_meta.dart';
import '../../widgets/achievements/achievement_icon.dart';
import '../../utils/verified_moment.dart';
import '../../widgets/core/v_feedback.dart';

/// Suggest a proof-backed Nexus moment after an achievement is verified.
Future<void> showNexusMomentSheet(
  BuildContext context, {
  required String achievementId,
}) {
  return showVSheet(
    context,
    NexusMomentSheet(achievementId: achievementId),
    maxSize: 0.75,
  );
}

class NexusMomentSheet extends ConsumerStatefulWidget {
  final String achievementId;

  const NexusMomentSheet({super.key, required this.achievementId});

  @override
  ConsumerState<NexusMomentSheet> createState() => _NexusMomentSheetState();
}

class _NexusMomentSheetState extends ConsumerState<NexusMomentSheet> {
  late final TextEditingController _controller;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    final achievement = ach_config.achievementForId(widget.achievementId);
    final title = achievement?.title ?? 'an achievement';
    _controller = TextEditingController(
      text: verifiedMomentDraft(title),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final content = _controller.text.trim();
    if (content.isEmpty) {
      VFeedback.showError(context, 'Add a short note for your Nexus moment.');
      return;
    }

    setState(() => _posting = true);
    try {
      await ref.read(postProvider.notifier).addPost(
            worldId: 'nexus',
            residentId: resident.id,
            residentName: resident.name,
            residentAvatar: resident.avatarUrl ?? '',
            content: content,
            tierValue: resident.tier.value,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      VFeedback.showMessage(context, 'Shared to your Nexus feed');
      context.go('/');
    } catch (_) {
      if (!mounted) return;
      VFeedback.showError(context, 'Could not post to Nexus. Try again.');
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final achievement = ach_config.achievementForId(widget.achievementId);
    final meta = achievement != null
        ? metaForCategory(achievement.category)
        : null;

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
            'Share to Nexus',
            style: TextStyle(
              fontSize: VFontSize.headlineMd,
              fontWeight: VFontWeight.bold,
              color: VCommuneColors.headerPrimaryOf(brightness),
            ),
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            'Share a proof-backed moment on your standing feed — not just a claim.',
            style: TextStyle(
              fontSize: VFontSize.bodySm,
              color: VCommuneColors.textMutedOf(brightness),
            ),
          ),
          if (achievement != null) ...[
            const SizedBox(height: VSpacing.md),
            Row(
              children: [
                AchievementBadgeAvatar(
                  achievement: achievement,
                  accentColor: meta!.color,
                  size: 44,
                  showEarnedBadge: true,
                ),
                const SizedBox(width: VSpacing.sm),
                Expanded(
                  child: Text(
                    achievement.title,
                    style: TextStyle(
                      fontWeight: VFontWeight.semiBold,
                      color: VCommuneColors.textNormalOf(brightness),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: VSpacing.md),
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'What does this milestone mean to you?',
              filled: true,
              fillColor: VCommuneColors.surfaceTertiaryOf(brightness),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VRadius.md),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: VSpacing.md),
          VButton(
            label: 'Post to Nexus',
            isFullWidth: true,
            isLoading: _posting,
            onPressed: _posting ? null : _publish,
          ),
          const SizedBox(height: VSpacing.sm),
          VButton(
            label: 'Not now',
            variant: ButtonVariant.text,
            isFullWidth: true,
            onPressed: _posting ? null : () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
