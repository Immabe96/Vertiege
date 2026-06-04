import 'package:flutter/material.dart';

import '../../models/world.dart';
import '../../theme/v_tokens.dart';
import '../core/v_dialog.dart';

/// Read-only constitution preview before joining a world (Wave 17).
Future<bool?> showWorldConstitutionPreview(
  BuildContext context, {
  required World world,
}) {
  final c = world.constitution;
  return showVDialog<bool>(
    context: context,
    title: '${world.name} — charter',
    scrollContent: true,
    maxContentHeight: 420,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Row(label: 'Admission', value: c.admission),
        if (c.minTier != null)
          _Row(label: 'Minimum tier', value: 'Tier ${c.minTier}'),
        if (c.requiredProfession != null)
          _Row(label: 'Profession', value: c.requiredProfession!),
        _Row(label: 'Posting', value: c.posting),
        _Row(label: 'Commenting', value: c.commenting),
        _Row(label: 'Content', value: c.contentTypes.join(', ')),
        if (c.entryFee > 0)
          _Row(label: 'Entry fee', value: '${c.entryFee} coins'),
        const SizedBox(height: VSpacing.sm),
        Text(
          world.description.isNotEmpty
              ? world.description
              : 'By joining you agree to follow this world\'s charter.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
    actions: [
      vDialogActionsRow([
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Join world'),
        ),
      ]),
    ],
  );
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: VFontWeight.semiBold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
