import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../forui/v_hub_page.dart';
import '../services/governance_service.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/core/v_feedback.dart';
import '../ui/buttons/v_button.dart';

class WorldGovernanceScreen extends ConsumerStatefulWidget {
  final String worldId;

  const WorldGovernanceScreen({super.key, required this.worldId});

  @override
  ConsumerState<WorldGovernanceScreen> createState() =>
      _WorldGovernanceScreenState();
}

class _WorldGovernanceScreenState extends ConsumerState<WorldGovernanceScreen> {
  List<GovernanceProposal> _proposals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await GovernanceService.listPending(widget.worldId);
    if (mounted) {
      setState(() {
        _proposals = list;
        _loading = false;
      });
    }
  }

  Future<void> _review(GovernanceProposal proposal, bool approve) async {
    final error = await GovernanceService.reviewProposal(
      proposalId: proposal.id,
      approve: approve,
    );
    if (!mounted) return;
    if (error != null) {
      VFeedback.showMessage(context, error);
      return;
    }
    VFeedback.showMessage(
      context,
      approve ? 'Proposal approved.' : 'Proposal rejected.',
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return VHubPage(
      title: 'Council queue',
      showBack: true,
      headerActions: [
        FHeaderAction(
          icon: const Icon(FIcons.rotateCw),
          onPress: _load,
        ),
      ],
      body: _loading
          ? const ScreenLoading.list()
          : _proposals.isEmpty
              ? const AppEmptyState(
                  title: 'Queue is clear',
                  description:
                      'Treasury withdrawals from council appear here when submitted. Only council and sovereign may withdraw.',
                  icon: Icons.gavel_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(VSpacing.md),
                  itemCount: _proposals.length,
                  separatorBuilder: (_, _) => const SizedBox(height: VSpacing.sm),
                  itemBuilder: (context, index) {
                    final p = _proposals[index];
                    final amount = p.payload['amount'];
                    final desc = p.payload['description'] as String? ?? '';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(VSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.proposalType.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (amount != null)
                              Text('Amount: $amount'),
                            if (desc.isNotEmpty) Text(desc),
                            const SizedBox(height: VSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: VButton(
                                    label: 'Reject',
                                    variant: ButtonVariant.outlined,
                                    onPressed: () => _review(p, false),
                                  ),
                                ),
                                const SizedBox(width: VSpacing.sm),
                                Expanded(
                                  child: VButton(
                                    label: 'Approve',
                                    onPressed: () => _review(p, true),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
