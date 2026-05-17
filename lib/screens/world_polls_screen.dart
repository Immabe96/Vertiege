import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/poll.dart';
import '../../services/poll_service.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/shimmer.dart';
import '../../widgets/core/empty_state.dart';

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
  bool _showActiveOnly = true;

  @override
  void initState() {
    super.initState();
    _loadPolls();
  }

  Future<void> _loadPolls() async {
    setState(() => _loading = true);
    try {
      final polls = await PollService.getPolls(
        widget.worldId,
        activeOnly: _showActiveOnly,
      );
      if (mounted) setState(() {
        _polls = polls;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreatePollDialog() {
    final questionController = TextEditingController();
    final options = ['', '', ''];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Poll'),
          content: SingleChildScrollView(
            child: Column(
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
                TextButton.icon(
                  onPressed: () {
                    options.add('');
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Option'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (questionController.text.trim().isEmpty) return;
                final validOptions = options.where((o) => o.trim().isNotEmpty).toList();
                if (validOptions.length < 2) return;

                await PollService.createPoll(
                  worldId: widget.worldId,
                  question: questionController.text.trim(),
                  options: validOptions,
                );
                if (context.mounted) {
                  Navigator.of(ctx).pop();
                  _loadPolls();
                }
              },
              child: const Text('Create'),
            ),
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
                Pulse(height: 16, width: double.infinity),
                SizedBox(height: VSpacing.sm),
                Pulse(height: 12, width: 100),
              ],
            ),
          );
        },
      );
    }

    if (_polls.isEmpty) {
      return AppEmptyState(
        title: 'No polls yet',
        description: widget.isSovereignOrCouncil
            ? 'Create the first poll for your world!'
            : 'No active polls in this world.',
        icon: Icons.how_to_vote_outlined,
        actionLabel: widget.isSovereignOrCouncil ? 'Create Poll' : null,
        onAction: widget.isSovereignOrCouncil ? _showCreatePollDialog : null,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(VSpacing.md),
          child: Row(
            children: [
              Text(
                '${_polls.length} poll${_polls.length == 1 ? '' : 's'}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const Spacer(),
              if (widget.isSovereignOrCouncil)
                FilledButton.icon(
                  onPressed: _showCreatePollDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('New Poll'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
            itemCount: _polls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: VSpacing.sm),
                child: _PollCard(
                  poll: _polls[index],
                  onVote: () => _loadPolls(),
                  onClose: () => _loadPolls(),
                  isSovereignOrCouncil: widget.isSovereignOrCouncil,
                ),
              );
            },
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
    final isDark = theme.brightness == Brightness.dark;
    final isActive = widget.poll.isActive;

    return Container(
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer,
        borderRadius: BorderRadius.circular(VRadius.lg),
        border: Border.all(
          color: isActive ? Colors.transparent : VColors.outline.withValues(alpha: 0.3),
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
                  padding: const EdgeInsets.symmetric(horizontal: VSpacing.xs, vertical: 2),
                  decoration: BoxDecoration(
                    color: VColors.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: Text(
                    widget.poll.isClosed ? 'Closed' : 'Expired',
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
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
                        : (isDark ? VColors.surfaceDark : VColors.surface),
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
                                fontWeight: isSelected ? VFontWeight.semiBold : VFontWeight.regular,
                              ),
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: VFontSize.labelSm,
                              color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
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
              color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
            ),
          ),
          if (widget.isSovereignOrCouncil && isActive)
            Padding(
              padding: const EdgeInsets.only(top: VSpacing.sm),
              child: TextButton(
                onPressed: () async {
                  await PollService.closePoll(widget.poll.id);
                  widget.onClose();
                },
                child: const Text('Close Poll'),
              ),
            ),
        ],
      ),
    );
  }
}
