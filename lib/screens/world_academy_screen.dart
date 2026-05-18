import '../../ui/icons/v_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import '../../models/challenge.dart';
import '../../services/challenge_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/shimmer.dart';
import '../../widgets/core/empty_state.dart';
import '../../ui/buttons/v_button.dart';

class WorldAcademyScreen extends ConsumerStatefulWidget {
  final String worldId;
  final bool isSovereignOrCouncil;

  const WorldAcademyScreen({
    super.key,
    required this.worldId,
    this.isSovereignOrCouncil = false,
  });

  @override
  ConsumerState<WorldAcademyScreen> createState() =>
      _WorldAcademyScreenState();
}

class _WorldAcademyScreenState extends ConsumerState<WorldAcademyScreen> {
  List<WorldChallenge> _challenges = [];
  bool _loading = true;
  final bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _loading = true);
    try {
      final challenges = await ChallengeService.getChallenges(
        widget.worldId,
        activeOnly: _showActiveOnly,
      );
      if (mounted) {
        setState(() {
        _challenges = challenges;
        _loading = false;
      });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateChallengeDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final targetController = TextEditingController();
    final rewardXpController = TextEditingController(text: '0');
    final rewardCurrencyController = TextEditingController(text: '0');
    String challengeType = 'individual';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Assignment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                FSelect<String>.rich(
                  format: (value) => value == 'individual' ? 'Individual' : 'Collective',
                  control: FSelectControl.lifted(
                    value: challengeType,
                    onChange: (v) { if (v != null) setDialogState(() => challengeType = v); },
                  ),
                  label: const Text('Type'),
                  hint: 'Select type',
                  children: const [
                    FSelectItem<String>(value: 'individual', title: Text('Individual')),
                    FSelectItem<String>(value: 'collective', title: Text('Collective')),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  decoration: const InputDecoration(
                    labelText: 'Target Value',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rewardXpController,
                        decoration: const InputDecoration(
                          labelText: 'XP Reward',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: rewardCurrencyController,
                        decoration: const InputDecoration(
                          labelText: 'Currency Reward',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            VButton(
              label: 'Cancel',
              onPressed: () => Navigator.of(ctx).pop(),
              variant: ButtonVariant.text,
            ),
            VButton(label: 'Create', onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              final target = int.tryParse(targetController.text);
              if (target == null || target <= 0) return;

              await ChallengeService.createChallenge(
                worldId: widget.worldId,
                title: titleController.text.trim(),
                description: descController.text.trim(),
                challengeType: challengeType,
                targetValue: target,
                rewardXp: int.tryParse(rewardXpController.text) ?? 0,
                rewardCurrency: int.tryParse(rewardCurrencyController.text) ?? 0,
              );
              if (context.mounted) {
                Navigator.of(ctx).pop();
                _loadChallenges();
              }
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(VSpacing.md),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: VSpacing.sm),
            padding: const EdgeInsets.all(VSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer,
              borderRadius: BorderRadius.circular(VRadius.lg),
            ),
            child: const Column(
              children: [
                Pulse(),
                SizedBox(height: VSpacing.sm),
                Pulse(height: 8),
              ],
            ),
          );
        },
      );
    }

    if (_challenges.isEmpty) {
      return AppEmptyState(
        title: 'No assignments',
        description: widget.isSovereignOrCouncil
            ? 'Create the first assignment!'
            : 'No active assignments in this world.',
        icon: Icons.school_outlined,
        actionLabel: widget.isSovereignOrCouncil ? 'Create Assignment' : null,
        onAction: widget.isSovereignOrCouncil ? _showCreateChallengeDialog : null,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(VSpacing.md),
          child: Row(
            children: [
              Text(
                '${_challenges.length} challenge${_challenges.length == 1 ? '' : 's'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.isSovereignOrCouncil)
                VButton(label: 'New Assignment', onPressed: _showCreateChallengeDialog, icon: const Icon(VIcons.plus)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
            itemCount: _challenges.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: VSpacing.sm),
                child: _ChallengeCard(
                  challenge: _challenges[index],
                  isSovereignOrCouncil: widget.isSovereignOrCouncil,
                  onToggle: _loadChallenges,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final WorldChallenge challenge;
  final bool isSovereignOrCouncil;
  final VoidCallback onToggle;

  const _ChallengeCard({
    required this.challenge,
    required this.isSovereignOrCouncil,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pct = challenge.progressPct;
    final isCompleted = challenge.isCompleted;

    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer,
        borderRadius: BorderRadius.circular(VRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: VSpacing.xs, vertical: 2),
                  decoration: BoxDecoration(
                    color: VColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      fontWeight: VFontWeight.semiBold,
                      color: VColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VSpacing.xs),
          Text(
            challenge.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          LinearProgressIndicator(value: pct),
          const SizedBox(height: VSpacing.xs),
          Row(
            children: [
              Text(
                '${challenge.currentValue} / ${challenge.targetValue}',
                style: TextStyle(
                  fontSize: VFontSize.labelSm,
                  fontWeight: VFontWeight.semiBold,
                  color: isCompleted ? VColors.success : VColors.primary,
                ),
              ),
              const Spacer(),
              if (challenge.rewardXp > 0)
                Text(
                  '+${challenge.rewardXp} XP',
                  style: const TextStyle(
                    fontSize: VFontSize.labelSm,
                    color: VColors.warning,
                  ),
                ),
              if (challenge.rewardCurrency > 0)
                Padding(
                  padding: const EdgeInsets.only(left: VSpacing.sm),
                  child: Text(
                    '+${challenge.rewardCurrency}',
                    style: const TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: VColors.tertiary,
                    ),
                  ),
                ),
            ],
          ),
          if (isSovereignOrCouncil && !isCompleted)
            Padding(
              padding: const EdgeInsets.only(top: VSpacing.sm),
              child: VButton(label: challenge.isActive ? 'Pause' : 'Resume', onPressed: () async {
                await ChallengeService.toggleChallenge(
                  challenge.id,
                  !challenge.isActive,
                );
                onToggle();
              }, variant: ButtonVariant.text),
            ),
        ],
      ),
    );
  }
}
