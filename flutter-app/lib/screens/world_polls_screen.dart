import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
import '../../models/poll.dart';
import '../../services/poll_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/empty_state.dart';
import '../../widgets/core/progression_help_button.dart';
import '../../config/progression_glossary.dart';
import '../../widgets/worlds/world_admin_breadcrumb.dart';

class WorldPollsScreen extends ConsumerStatefulWidget {
  final String worldId;
  final bool isSovereignOrCouncil;

  const WorldPollsScreen({
    super.key,
    required this.worldId,
    this.isSovereignOrCouncil = false,
  });

  @override
  ConsumerState<WorldPollsScreen> createState() => _WorldPollsScreenState();
}

class _WorldPollsScreenState extends ConsumerState<WorldPollsScreen> {
  List<WorldPoll> _polls = [];
  bool _loading = true;
  String? _loadError;
  final bool _showActiveOnly = true;
  bool _canCreatePoll = false;

  @override
  void initState() {
    super.initState();
    _loadPolls();
    _loadCanCreate();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeOpenCreateFromRoute(),
    );
  }

  Future<void> _maybeOpenCreateFromRoute() async {
    final create =
        GoRouterState.of(context).uri.queryParameters['create'] == 'true';
    if (!create) return;
    await _loadCanCreate();
    if (!mounted) return;
    if (_canCreatePoll) {
      _showCreatePollDialog();
    }
  }

  Future<void> _loadCanCreate() async {
    final allowed = await PollService.canCreatePoll(widget.worldId);
    if (mounted) setState(() => _canCreatePoll = allowed);
  }

  Future<void> _loadPolls() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final polls = await PollService.getPolls(
        widget.worldId,
        activeOnly: _showActiveOnly,
      );
      if (mounted) {
        setState(() {
          _polls = polls;
          _loading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Could not load polls. Please try again.';
        });
      }
    }
  }

  Future<void> _showCreatePollDialog() async {
    final questionController = TextEditingController();
    final options = ['', '', ''];

    try {
      await showVDialog<void>(
        context: context,
        title: 'Create Poll',
        scrollContent: true,
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Options'),
              const SizedBox(height: 8),
              ...options.asMap().entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    onChanged: (v) {
                      options[e.key] = v;
                      setDialogState(() {});
                    },
                    decoration: InputDecoration(
                      labelText: 'Option ${e.key + 1}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              }),
              VButton(
                label: 'Add Option',
                onPressed: () {
                  options.add('');
                  setDialogState(() {});
                },
                icon: const Icon(VIcons.plus),
                variant: ButtonVariant.text,
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
                if (questionController.text.trim().isEmpty) return;
                final validOptions = options
                    .where((o) => o.trim().isNotEmpty)
                    .toList();
                if (validOptions.length < 2) return;

                try {
                  await PollService.createPoll(
                    worldId: widget.worldId,
                    question: questionController.text.trim(),
                    options: validOptions,
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  _loadPolls();
                } catch (e) {
                  if (!mounted) return;
                  VFeedback.showMessage(
                    context,
                    e is StateError ? e.message : 'Could not create poll.',
                  );
                }
              },
            ),
          ]),
        ],
      );
    } finally {
      questionController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VHubPage(
      title: 'Polls',
      titleWidget: WorldAdminBreadcrumb(
        worldId: widget.worldId,
        sectionTitle: 'Polls',
      ),
      showBack: true,
      headerActions: [
        const ProgressionHelpButton(
          focus: ProgressionFocus.worldPolls,
          tooltip: 'How polls work',
        ),
        if (_canCreatePoll)
          VHeaderAction(
            icon: const Icon(VIcons.plus),
            onPress: _showCreatePollDialog,
          ),
      ],
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const ScreenLoading.list();
    }

    if (_loadError != null) {
      return AppErrorState(message: _loadError, onRetry: _loadPolls);
    }

    if (_polls.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPolls,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            AppEmptyState(
              title: 'No polls yet',
              description: _canCreatePoll
                  ? 'Ask the world a question—create the first poll.'
                  : 'No active polls right now. Check back when council posts one.',
              icon: Icons.how_to_vote_outlined,
              actionLabel: widget.isSovereignOrCouncil ? 'Create Poll' : null,
              onAction:
                  widget.isSovereignOrCouncil ? _showCreatePollDialog : null,
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
              '${_polls.length} active poll${_polls.length == 1 ? '' : 's'}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: VFontWeight.semiBold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadPolls,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
              itemCount: _polls.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: VSpacing.sm),
                  child: _PollCard(
                    poll: _polls[index],
                    onVote: _loadPolls,
                    onClose: _loadPolls,
                    isSovereignOrCouncil: widget.isSovereignOrCouncil,
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

class _PollCard extends StatefulWidget {
  final WorldPoll poll;
  final VoidCallback onVote;
  final VoidCallback onClose;
  final bool isSovereignOrCouncil;

  const _PollCard({
    required this.poll,
    required this.onVote,
    required this.onClose,
    required this.isSovereignOrCouncil,
  });

  @override
  State<_PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<_PollCard> {
  int? _selectedOption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.poll.isActive;

    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerDark,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isActive
              ? Colors.transparent
              : VColors.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.poll.question,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: VFontWeight.bold,
                  ),
                ),
              ),
              if (!isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: VColors.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: Text(
                    widget.poll.isClosed ? 'Closed' : 'Expired',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VSpacing.sm),
          ...widget.poll.options.asMap().entries.map((e) {
            final votes = widget.poll.results[e.key] ?? 0;
            final pct = widget.poll.totalVotes > 0
                ? (votes / widget.poll.totalVotes * 100).round()
                : 0;
            final isSelected = _selectedOption == e.key;

            return Padding(
              padding: const EdgeInsets.only(bottom: VSpacing.xs),
              child: GestureDetector(
                onTap: isActive && _selectedOption == null
                    ? () async {
                        setState(() => _selectedOption = e.key);
                        await PollService.voteOnPoll(widget.poll.id, e.key);
                        widget.onVote();
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(VSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? VColors.primary.withValues(alpha: 0.1)
                        : VColors.surfaceDark,
                    borderRadius: BorderRadius.circular(VRadius.md),
                    border: Border.all(
                      color: isSelected ? VColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (isActive && _selectedOption != null)
                        FractionallySizedBox(
                          widthFactor: pct / 100,
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: VColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(VRadius.md),
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.value,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? VFontWeight.semiBold
                                    : VFontWeight.regular,
                              ),
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: VFontSize.labelSm,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: VSpacing.xs),
          Text(
            '${widget.poll.totalVotes} vote${widget.poll.totalVotes == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: VFontSize.labelSm,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (widget.isSovereignOrCouncil && isActive)
            Padding(
              padding: const EdgeInsets.only(top: VSpacing.sm),
              child: VButton(
                label: 'Close Poll',
                onPressed: () async {
                  await PollService.closePoll(widget.poll.id);
                  widget.onClose();
                },
                variant: ButtonVariant.text,
              ),
            ),
        ],
      ),
    );
  }
}
