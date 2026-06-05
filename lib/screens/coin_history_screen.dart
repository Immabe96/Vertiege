import 'package:flutter/material.dart';
import 'package:vertiege/ui/ui.dart';
import '../services/coin_ledger_service.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';
import '../widgets/core/empty_state.dart';
import '../widgets/core/screen_loading.dart';

/// Sovereign coin ledger history (Wave 18 data, Wave 22 UI).
class CoinHistoryScreen extends StatefulWidget {
  const CoinHistoryScreen({super.key});

  @override
  State<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends State<CoinHistoryScreen> {
  List<CoinTransaction>? _rows;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await CoinLedgerService.listRecent(limit: 50);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load coin history';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return VHubPage(
      title: 'Coin history',
      showBack: true,
      headerActions: [
        VHeaderAction(icon: Icon(VIcons.rotateCw), onPress: _load),
      ],
      body: _loading
          ? const ScreenLoading.list()
          : _error != null
          ? AppErrorState(message: _error, onRetry: _load)
          : (_rows == null || _rows!.isEmpty)
          ? const AppEmptyState(
              title: 'No transactions yet',
              description: 'Earn or spend sovereign coins to see entries here.',
              icon: Icons.monetization_on_outlined,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(VSpacing.md),
                itemCount: _rows!.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: VSpacing.sm),
                itemBuilder: (context, index) {
                  final tx = _rows![index];
                  final positive = tx.amount >= 0;
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(VRadius.md),
                      side: BorderSide(
                        color: isDark
                            ? VColors.outlineVariantDark
                            : VColors.outlineVariant,
                      ),
                    ),
                    leading: Icon(
                      positive
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      color: positive ? VColors.success : VColors.error,
                    ),
                    title: Text(_reasonLabel(tx.reason)),
                    subtitle: Text(
                      _formatWhen(tx.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Text(
                      '${positive ? '+' : ''}${tx.amount}',
                      style: TextStyle(
                        fontWeight: VFontWeight.bold,
                        color: positive ? VColors.success : VColors.error,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  static String _reasonLabel(String reason) {
    if (reason.isEmpty) return 'Transaction';
    return reason
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _formatWhen(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
