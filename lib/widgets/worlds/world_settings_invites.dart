import 'package:flutter/material.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import '../../models/invite.dart';
import '../../utils/date_format.dart';
import '../../widgets/core/glass_panel.dart';
import '../../widgets/core/loading_state.dart';

class WorldSettingsInvites extends StatelessWidget {
  final String? sovereignId;
  final String? residentId;
  final bool isGenerating;
  final String? generatedCode;
  final List<WorldInvite> invites;
  final bool isLoadingInvites;
  final VoidCallback onGenerate;
  final void Function(String code) onCopy;

  const WorldSettingsInvites({
    super.key,
    required this.sovereignId,
    required this.residentId,
    required this.isGenerating,
    required this.generatedCode,
    required this.invites,
    required this.isLoadingInvites,
    required this.onGenerate,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.person_add,
              color: VColors.tertiary,
              size: VIconSize.sm,
            ),
            const SizedBox(width: VSpacing.sm),
            Text(
              'Invites',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: VFontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpacing.sm),
        Text(
          'Create and manage invitation links for this world.',
          style: theme.textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
        const SizedBox(height: VSpacing.md),
        if (residentId == sovereignId)
          SizedBox(
            width: double.infinity,
            height: VTouchTarget.minimum,
            child: OutlinedButton.icon(
              onPressed: isGenerating ? null : onGenerate,
              icon: isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.link),
              label: Text(isGenerating ? 'Generating...' : 'Generate Invite'),
            ),
          ),
        if (generatedCode != null) ...[
          const SizedBox(height: VSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller: TextEditingController(text: generatedCode),
                  decoration: InputDecoration(
                    hintText: 'Invite Code',
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    letterSpacing: 2,
                    fontFamily: VFont.mono,
                  ),
                ),
              ),
              const SizedBox(width: VSpacing.sm),
              IconButton.filled(
                onPressed: () => onCopy(generatedCode!),
                icon: const Icon(Icons.copy),
                tooltip: 'Copy link',
              ),
            ],
          ),
        ],
        if (isLoadingInvites) ...[
          const SizedBox(height: VSpacing.md),
          const VLoadingCard(),
        ] else if (invites.isNotEmpty) ...[
          const SizedBox(height: VSpacing.md),
          const Divider(),
          const SizedBox(height: VSpacing.sm),
          Text('Existing Invites', style: theme.textTheme.labelLarge),
          const SizedBox(height: VSpacing.sm),
          ...invites.map(
            (invite) => _InviteRow(invite: invite, onCopy: onCopy),
          ),
        ],
      ],
    );
  }
}

class _InviteRow extends StatelessWidget {
  final WorldInvite invite;
  final void Function(String code) onCopy;

  const _InviteRow({required this.invite, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valid = invite.isValid;
    final displayDate = invite.createdAt > 0
        ? formatTimestamp(invite.createdAt)
        : 'Unknown date';
    final usesLabel = invite.maxUses > 0
        ? '${invite.uses}/${invite.maxUses} uses'
        : '${invite.uses} uses (unlimited)';

    return Padding(
      padding: const EdgeInsets.only(bottom: VSpacing.sm),
      child: VSurfacePanel(
        padding: const EdgeInsets.all(VSpacing.md),
        borderRadius: BorderRadius.circular(VRadius.xl),
        child: Row(
          children: [
            Icon(
              valid ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: valid ? Theme.of(context).colorScheme.primary : VColors.error,
              size: VIconSize.md,
            ),
            const SizedBox(width: VSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invite.code,
                    style: TextStyle(
                      fontFamily: VFont.mono,
                      letterSpacing: 1,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '$usesLabel  ·  $displayDate'
                    '${invite.isExpired ? '  ·  Expired' : ''}'
                    '${invite.isExhausted ? '  ·  Exhausted' : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: VIconSize.base),
              onPressed: () => onCopy(invite.code),
              tooltip: 'Copy link',
            ),
          ],
        ),
      ),
    );
  }
}
