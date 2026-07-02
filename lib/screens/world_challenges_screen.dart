import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vertiege/ui/ui.dart';
import '../../models/challenge.dart';
import '../../services/challenge_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/worlds/world_admin_breadcrumb.dart';

class WorldChallengesScreen extends ConsumerStatefulWidget {
  final String worldId;
  final bool isSovereignOrCouncil;

  const WorldChallengesScreen({
    super.key,
    required this.worldId,
    this.isSovereignOrCouncil = false,
  });

  @override
  ConsumerState<WorldChallengesScreen> createState() =>
      _WorldChallengesScreenState();
}

class _WorldChallengesScreenState extends ConsumerState<WorldChallengesScreen> {
  List<WorldChallenge> _challenges = [];
  bool _loading = true;
  String? _loadError;
  final bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final challenges = await ChallengeService.getChallenges(
        widget.worldId,
        activeOnly: _showActiveOnly,
      );
      if (mounted) {
        setState(() {
          _challenges = challenges;
          _loading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Could not load challenges. Please try again.';
        });
      }
    }
  }

  Future<void> _showCreateChallengeDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final targetController = TextEditingController();
    final rewardXpController = TextEditingController(text: '0');
    final rewardCurrencyController = TextEditingController(text: '0');
    String challengeType = 'individual';
    String challengeScope = 'world';

    try {
      await showVDialog<void>(
        context: context,
        title: 'Create Challenge',
        scrollContent: true,
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: VSpacing.lg),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: VSpacing.lg),
              VSelect<String>(
                value: challengeType,
                onChanged: (v) {
                  if (v != null) setDialogState(() => challengeType = v);
                },
                format: (value) =>
                    value == 'individual' ? 'Individual' : 'Collective',
                label: const Text('Type'),
                hint: 'Select type',
                items: const [
                  VSelectItem(value: 'individual', title: Text('Individual')),
                  VSelectItem(value: 'collective', title: Text('Collective')),
                ],
              ),
              const SizedBox(height: VSpacing.lg),
              VSelect<String>(
                value: challengeScope,
                onChanged: (v) {
                  if (v != null) setDialogState(() => challengeScope = v);
                },
                format: (value) =>
                    value == 'season' ? 'Season cohort' : 'World',
                label: const Text('Scope'),
                hint: 'Select scope',
                items: const [
                  VSelectItem(value: 'world', title: Text('World')),
                  VSelectItem(value: 'season', title: Text('Season cohort')),
                ],
              ),
              const SizedBox(height: VSpacing.lg),
              TextField(
                controller: targetController,
                decoration: const InputDecoration(
                  labelText: 'Target Value',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: VSpacing.lg),
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
          vDialogActionsRow([
            VButton(
              label: 'Cancel',
              onPressed: () => Navigator.pop(context),
              variant: ButtonVariant.text,
            ),
            VButton(
              label: 'Create',
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final target = int.tryParse(targetController.text);
                if (target == null || target <= 0) return;

                await ChallengeService.createChallenge(
                  worldId: widget.worldId,
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  challengeType: challengeType,
                  scope: challengeScope,
                  targetValue: target,
                  rewardXp: int.tryParse(rewardXpController.text) ?? 0,
                  rewardCurrency: int.tryParse(rewardCurrencyController.text) ?? 0,
                );
                if (!mounted) return;
                Navigator.pop(context);
                _loadChallenges();
              },
            ),
          ]),
        ],
      );
    } finally {
      titleController.dispose();
      descController.dispose();
      targetController.dispose();
      rewardXpController.dispose();
      rewardCurrencyController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VHubPage(
      title: 'Challenges',
      titleWidget: WorldAdminBreadcrumb(
        worldId: widget.worldId,
        sectionTitle: 'Challenges',
      ),
      showBack: true,
      headerActions: widget.isSovereignOrCouncil
          ? [
              VHeaderAction(
                icon: const Icon(VIcons.plus),
                onPress: _showCreateChallengeDialog,
              ),
            ]
          : const [],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const ScreenLoading.list();
    }

    if (_loadError != null) {
      return AppErrorState(message: _loadError, onRetry: _loadChallenges);
    }

    if (_challenges.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadChallenges,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AppEmptyState(
              title: 'No challenges yet',
              description: widget.isSovereignOrCouncil
                  ? 'Set a goal for residents—create the first world challenge.'
                  : 'No active challenges right now. Join in when council launches one.',
              icon: Icons.flag_outlined,
              actionLabel:
                  widget.isSovereignOrCouncil ? 'Create Challenge' : null,
              onAction: widget.isSovereignOrCouncil
                  ? _showCreateChallengeDialog
                  : null,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VSpacing.md,
            VSpacing.md,
            VSpacing.md,
            VSpacing.sm,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_challenges.length} active challenge${_challenges.length == 1 ? '' : 's'}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: VFontWeight.semiBold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadChallenges,
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
    final pct = challenge.progressPct;
    final isCompleted = challenge.isCompleted;

    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerDark,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.xs,
                    vertical: 2,
                  ),
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
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: VColors.surfaceDark,
            valueColor: AlwaysStoppedAnimation(
              isCompleted ? VColors.success : VColors.primary,
            ),
            minHeight: 8,
          ),
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
              child: VButton(
                label: challenge.isActive ? 'Pause' : 'Resume',
                onPressed: () async {
                  await ChallengeService.toggleChallenge(
                    challenge.id,
                    !challenge.isActive,
                  );
                  onToggle();
                },
                variant: ButtonVariant.text,
              ),
            ),
        ],
      ),
    );
  }
}
