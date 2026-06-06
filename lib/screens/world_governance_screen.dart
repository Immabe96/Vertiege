import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vertiege/ui/ui.dart';
import '../router/world_navigation.dart';
import '../services/governance_service.dart';
import '../theme/v_tokens.dart';
import '../utils/haptics.dart';
import '../utils/provider_errors.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';
import '../widgets/worlds/world_admin_breadcrumb.dart';

class WorldGovernanceScreen extends ConsumerStatefulWidget {
  final String worldId;
  final String? worldName;

  const WorldGovernanceScreen({
    super.key,
    required this.worldId,
    this.worldName,
  });

  @override
  ConsumerState<WorldGovernanceScreen> createState() =>
      _WorldGovernanceScreenState();
}

class _WorldGovernanceScreenState extends ConsumerState<WorldGovernanceScreen> {
  List<GovernanceProposal> _proposals = [];
  Map<String, String> _names = {};
  Map<String, String> _rankNames = {};
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final enriched = await GovernanceService.listPendingEnriched(
        widget.worldId,
      );
      if (!mounted) return;
      setState(() {
        _proposals = enriched.proposals;
        _names = enriched.names;
        _rankNames = enriched.rankNames;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = userFacingLoadError(e);
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
        final rankId = p.payload['rank_id'] as String?;
        final rankLabel = rankId != null
            ? (_rankNames[rankId] ?? 'rank')
            : 'rank';
        final verb = p.payload['action'] == 'remove' ? 'Remove' : 'Assign';
        return '$verb $rankLabel · $target · $from';
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
    if (approve) Haptics.medium();
    VFeedback.showMessage(context, approve ? 'Approved.' : 'Rejected.');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return VHubPage(
      title: 'Council queue',
      titleWidget: WorldAdminBreadcrumb(
        worldId: widget.worldId,
        sectionTitle: 'Governance',
      ),
      showBack: true,
      headerActions: [
        VHeaderAction(
          icon: const Icon(VIcons.rotateCw),
          onPress: _load,
        ),
      ],
      body: _loadError != null
          ? AppErrorState(message: _loadError!, onRetry: _load)
          : _loading
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
              itemCount: _proposals.length + 1,
              itemBuilder: (context, index) {
                if (index == _proposals.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: VSpacing.md),
                    child: VButton(
                      label: 'View realm audit',
                      variant: ButtonVariant.text,
                      onPressed: () => context.push(
                        auditLogPath(
                          widget.worldId,
                          worldName: widget.worldName ?? 'World',
                        ),
                      ),
                    ),
                  );
                }
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
                              child: SizedBox(
                                height: 48,
                                child: VButton(
                                  label: 'Reject',
                                  variant: ButtonVariant.outlined,
                                  onPressed: () => _review(p, false),
                                ),
                              ),
                            ),
                            const SizedBox(width: VSpacing.sm),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: VButton(
                                  label: 'Approve',
                                  onPressed: () => _review(p, true),
                                ),
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
