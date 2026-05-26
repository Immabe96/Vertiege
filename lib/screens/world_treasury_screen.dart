import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../forui/v_hub_page.dart';
import '../../config/world_capability_matrix.dart';
import '../../models/treasury.dart';
import '../../services/treasury_service.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../widgets/core/screen_loading.dart';
import '../../widgets/core/v_feedback.dart';
import '../../widgets/core/empty_state.dart';
import '../ui/buttons/v_button.dart';
import '../widgets/worlds/world_capability_hint.dart';

class WorldTreasuryScreen extends ConsumerStatefulWidget {
  final String worldId;
  final bool isSovereignOrCouncil;

  const WorldTreasuryScreen({
    super.key,
    required this.worldId,
    this.isSovereignOrCouncil = false,
  });

  @override
  ConsumerState<WorldTreasuryScreen> createState() =>
      _WorldTreasuryScreenState();
}

class _WorldTreasuryScreenState extends ConsumerState<WorldTreasuryScreen> {
  WorldTreasury? _treasury;
  List<TreasuryTransaction> _transactions = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final treasury = await TreasuryService.getTreasury(widget.worldId);
      final transactions = await TreasuryService.getTransactions(widget.worldId);
      if (mounted) {
        setState(() {
          _treasury = treasury;
          _transactions = transactions;
          _loading = false;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Could not load treasury. Please try again.';
        });
      }
    }
  }

  void _showDonateDialog() {
    final resident = ref.read(residentProvider).resident;
    final world = ref.read(worldProvider).worlds[widget.worldId];
    if (world != null) {
      final block = WorldCapabilityMatrix.blockReasonTreasuryDonate(
        resident,
        world,
        isJoined: true,
      );
      if (block != null) {
        VFeedback.showMessage(context, block);
        return;
      }
    }

    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Donate to Treasury'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Donate',
            onPressed: () async {
              final amount = int.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;

              await TreasuryService.donate(
                widget.worldId,
                amount,
                descController.text.trim(),
              );
              if (context.mounted) {
                Navigator.of(ctx).pop();
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw from Treasury'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          VButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(ctx).pop(),
            variant: ButtonVariant.text,
          ),
          VButton(
            label: 'Withdraw',
            onPressed: () async {
              final amount = int.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;

              await TreasuryService.withdraw(
                widget.worldId,
                amount,
                descController.text.trim(),
              );
              if (context.mounted) {
                Navigator.of(ctx).pop();
                _loadData();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final world = ref.watch(worldProvider).worlds[widget.worldId];
    final donateBlock = world != null
        ? WorldCapabilityMatrix.blockReasonTreasuryDonate(
            ref.watch(residentProvider).resident,
            world,
            isJoined: true,
          )
        : null;

    return VHubPage(
      title: 'Treasury',
      showBack: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WorldCapabilityHint(
            message: donateBlock ??
                'Treasury unlocks at world prestige '
                '${WorldCapabilityMatrix.minWorldPrestigeTreasury}. '
                'Marketplace sales feed tax here.',
            icon: Icons.account_balance_outlined,
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);
    final world = ref.watch(worldProvider).worlds[widget.worldId];
    final taxRate = world?.taxRate ?? 0;

    if (_loading) {
      return const ScreenLoading.detail();
    }

    if (_loadError != null) {
      return AppErrorState(message: _loadError, onRetry: _loadData);
    }

    if (_treasury == null) {
      return AppEmptyState(
        title: 'No treasury yet',
        description: widget.isSovereignOrCouncil
            ? 'World treasury will appear here once funded. Residents can donate when it is active.'
            : 'This world has not opened a treasury yet. Check back after the sovereign sets one up.',
        icon: Icons.account_balance_outlined,
        actionLabel: widget.isSovereignOrCouncil ? 'Refresh' : null,
        onAction: widget.isSovereignOrCouncil ? _loadData : null,
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(VSpacing.md),
          padding: const EdgeInsets.all(VSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                VColors.primary.withValues(alpha: 0.2),
                VColors.tertiary.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(VRadius.xl),
          ),
          child: Column(
            children: [
              Text(
                'Treasury Balance',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: VFontWeight.semiBold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                '${_treasury!.balance}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                  color: VColors.tertiary,
                ),
              ),
              if (taxRate > 0) ...[
                const SizedBox(height: VSpacing.sm),
                Text(
                  'Marketplace purchases route $taxRate% to this treasury',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: VSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatCard(
                    label: 'Total Donated',
                    value: _treasury!.totalDonated.toString(),
                    icon: Icons.arrow_downward,
                    color: VColors.success,
                  ),
                  _StatCard(
                    label: 'Total Spent',
                    value: _treasury!.totalSpent.toString(),
                    icon: Icons.arrow_upward,
                    color: VColors.error,
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _showDonateDialog,
                      icon: const Icon(Icons.volunteer_activism),
                      label: const Text('Donate'),
                    ),
                  ),
                  if (widget.isSovereignOrCouncil) ...[
                    const SizedBox(width: VSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showWithdrawDialog,
                        icon: const Icon(Icons.money_off),
                        label: const Text('Withdraw'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
          child: Row(
            children: [
              Text(
                'Transactions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.sm),
        Expanded(
          child: _transactions.isEmpty
              ? AppEmptyState(
                  title: 'No transactions yet',
                  description: 'Donations, withdrawals, and rewards show up here.',
                  icon: Icons.receipt_long_outlined,
                  actionLabel: 'Donate',
                  onAction: _showDonateDialog,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: VSpacing.md),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final tx = _transactions[index];
                    return _TransactionTile(transaction: tx);
                  },
                ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, size: VIconSize.md, color: color),
        const SizedBox(height: VSpacing.xs),
        Text(
          value,
          style: TextStyle(
            fontWeight: VFontWeight.bold,
            fontSize: VFontSize.bodyLg,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TreasuryTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: VSpacing.xs),
      padding: const EdgeInsets.all(VSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceDark : VColors.surfaceContainer,
        borderRadius: BorderRadius.circular(VRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _txColor(transaction.transactionType).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(VRadius.sm),
            ),
            child: Icon(
              _txIcon(transaction.transactionType),
              size: VIconSize.sm,
              color: _txColor(transaction.transactionType),
            ),
          ),
          const SizedBox(width: VSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.transactionType.name[0].toUpperCase() +
                      transaction.transactionType.name.substring(1),
                  style: const TextStyle(fontWeight: VFontWeight.semiBold),
                ),
                if (transaction.description.isNotEmpty)
                  Text(
                    transaction.description,
                    style: TextStyle(
                      fontSize: VFontSize.labelSm,
                      color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Text(
            '${transaction.transactionType == TreasuryTransactionType.withdrawal ? '-' : '+'}${transaction.amount}',
            style: TextStyle(
              fontWeight: VFontWeight.bold,
              color: _txColor(transaction.transactionType),
            ),
          ),
        ],
      ),
    );
  }

  Color _txColor(TreasuryTransactionType type) {
    switch (type) {
      case TreasuryTransactionType.donation:
        return VColors.success;
      case TreasuryTransactionType.withdrawal:
        return VColors.error;
      case TreasuryTransactionType.tax:
        return VColors.warning;
      case TreasuryTransactionType.reward:
        return VColors.primary;
      case TreasuryTransactionType.refund:
        return VColors.tertiary;
    }
  }

  IconData _txIcon(TreasuryTransactionType type) {
    switch (type) {
      case TreasuryTransactionType.donation:
        return Icons.volunteer_activism;
      case TreasuryTransactionType.withdrawal:
        return Icons.money_off;
      case TreasuryTransactionType.tax:
        return Icons.percent;
      case TreasuryTransactionType.reward:
        return Icons.emoji_events;
      case TreasuryTransactionType.refund:
        return Icons.restore;
    }
  }
}
