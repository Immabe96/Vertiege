import 'package:flutter/material.dart';

import '../models/report.dart';
import '../ui/ui.dart';
import '../theme/v_colors.dart';
import '../theme/v_tokens.dart';

/// Shared reason-picker bottom sheet for reporting posts and chat messages.
class ReportSheet extends StatefulWidget {
  final void Function(ReportReason reason, String? details) onSubmit;
  final String targetLabel; // e.g. "post" or "message"

  const ReportSheet({
    super.key,
    required this.onSubmit,
    this.targetLabel = 'post',
  });

  @override
  State<ReportSheet> createState() => _ReportSheetState();

  /// Show the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required void Function(ReportReason reason, String? details) onSubmit,
    String targetLabel = 'post',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => ReportSheet(
        onSubmit: onSubmit,
        targetLabel: targetLabel,
      ),
    );
  }
}

class _ReportSheetState extends State<ReportSheet> {
  ReportReason _reason = ReportReason.spam;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: VSpacing.md,
        right: VSpacing.md,
        top: VSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + VSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report ${widget.targetLabel}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: VSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReportReason.values.map((r) {
              final selected = _reason == r;
              return ChoiceChip(
                label: Text(r.label),
                selected: selected,
                onSelected: (_) => setState(() => _reason = r),
              );
            }).toList(),
          ),
          const SizedBox(height: VSpacing.sm),
          TextField(
            controller: _detailsController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Additional details (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          VButton(
            label: 'Submit Report',
            onPressed: () => widget.onSubmit(
              _reason,
              _detailsController.text.trim().isEmpty
                  ? null
                  : _detailsController.text.trim(),
            ),
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
