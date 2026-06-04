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
  Map<String, String> _names = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final enriched =
        await GovernanceService.listPendingEnriched(widget.worldId);
    if (mounted) {
      setState(() {
        _proposals = enriched.proposals;
        _names = enriched.names;
        _loading = false;
      });
    }
  }

  String _name(String? id) {
    if (id == null || id.isEmpty) return 'Someone';
    return _names[id] ?? 'Resident';
  }

  String _proposalTitle(GovernanceProposal p) {
    switch (p.proposalType) {
      case 'treasury_withdrawal':
        return 'Treasury withdrawal';
      case 'job_publish':
        return 'Role post';
      case 'rank_change':
        return p.payload['action'] == 'remove' ? 'Remove rank' : 'Assign rank';
      default:
        return p.proposalType.replaceAll('_', ' ');
    }
  }

  String _proposalSubtitle(GovernanceProposal p) {
    final from = _name(p.requestedBy);
    switch (p.proposalType) {
      case 'treasury_withdrawal':
        final amount = p.payload['amount'];
        final desc = p.payload['description'] as String? ?? '';
        final parts = <String>[
          'From $from',
          if (amount != null) '$amount coins',
          if (desc.isNotEmpty) desc,
        ];
        return parts.join(' · ');
      case 'job_publish':
        final title = p.payload['title'] as String? ?? '';
        return title.isEmpty ? 'From $from' : '$title · $from';
      case 'rank_change':
        final target = _name(p.payload['resident_id'] as String?);
        return '$target · $from';
      default:
        return from;
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
      approve ? 'Approved.' : 'Rejected.',
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
                      'Withdrawals, role posts, and rank changes appear here when members request them.',
                  icon: Icons.gavel_outlined,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(VSpacing.md),
                  itemCount: _proposals.length,
                  itemBuilder: (context, index) {
                    final p = _proposals[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: VSpacing.sm),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: VSpacing.md,
                        ),
                        title: Text(
                          _proposalTitle(p),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          _proposalSubtitle(p),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              VSpacing.md,
                              0,
                              VSpacing.md,
                              VSpacing.md,
                            ),
                            child: Row(
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
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
