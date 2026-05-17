import 'package:flutter/material.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';

class ConstitutionEditor extends StatefulWidget {
  final WorldConstitution initial;
  final ValueChanged<WorldConstitution> onChanged;

  const ConstitutionEditor({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<ConstitutionEditor> createState() => _ConstitutionEditorState();
}

class _ConstitutionEditorState extends State<ConstitutionEditor> {
  late WorldConstitution _constitution;

  @override
  void initState() {
    super.initState();
    _constitution = widget.initial;
  }

  void _update(VoidCallback fn) {
    setState(fn);
    widget.onChanged(_constitution);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Constitution',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: VFontWeight.bold,
          ),
        ),
        const SizedBox(height: VSpacing.lg),
        _Section(
          title: 'Admission',
          isDark: isDark,
          child: Column(
            children: [
              _RadioTile(
                title: 'Open',
                subtitle: 'Anyone can join',
                value: 'open',
                groupValue: _constitution.admission,
                onChanged: (v) => _update(() => _constitution = WorldConstitution(
                  admission: v!,
                  minTier: _constitution.minTier,
                  requiredProfession: _constitution.requiredProfession,
                  posting: _constitution.posting,
                  commenting: _constitution.commenting,
                  contentTypes: _constitution.contentTypes,
                  entryFee: _constitution.entryFee,
                  allowAnonymous: _constitution.allowAnonymous,
                  requireApproval: _constitution.requireApproval,
                  language: _constitution.language,
                )),
              ),
              _RadioTile(
                title: 'Invite Only',
                subtitle: 'Requires an invite code',
                value: 'invite-only',
                groupValue: _constitution.admission,
                onChanged: (v) => _update(() => _constitution = WorldConstitution(
                  admission: v!,
                  minTier: _constitution.minTier,
                  requiredProfession: _constitution.requiredProfession,
                  posting: _constitution.posting,
                  commenting: _constitution.commenting,
                  contentTypes: _constitution.contentTypes,
                  entryFee: _constitution.entryFee,
                  allowAnonymous: _constitution.allowAnonymous,
                  requireApproval: _constitution.requireApproval,
                  language: _constitution.language,
                )),
              ),
              _RadioTile(
                title: 'Application',
                subtitle: 'Sovereign approves each member',
                value: 'application',
                groupValue: _constitution.admission,
                onChanged: (v) => _update(() => _constitution = WorldConstitution(
                  admission: v!,
                  minTier: _constitution.minTier,
                  requiredProfession: _constitution.requiredProfession,
                  posting: _constitution.posting,
                  commenting: _constitution.commenting,
                  contentTypes: _constitution.contentTypes,
                  entryFee: _constitution.entryFee,
                  allowAnonymous: _constitution.allowAnonymous,
                  requireApproval: _constitution.requireApproval,
                  language: _constitution.language,
                )),
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.md),
        _Section(
          title: 'Permissions',
          isDark: isDark,
          child: Column(
            children: [
              _DropdownTile(
                label: 'Who can post?',
                value: _constitution.posting,
                items: const [
                  ('all-members', 'All Members'),
                  ('council-only', 'Council Only'),
                  ('sovereign-only', 'Sovereign Only'),
                ],
                onChanged: (v) => _update(() => _constitution = WorldConstitution(
                  admission: _constitution.admission,
                  minTier: _constitution.minTier,
                  requiredProfession: _constitution.requiredProfession,
                  posting: v!,
                  commenting: _constitution.commenting,
                  contentTypes: _constitution.contentTypes,
                  entryFee: _constitution.entryFee,
                  allowAnonymous: _constitution.allowAnonymous,
                  requireApproval: _constitution.requireApproval,
                  language: _constitution.language,
                )),
              ),
              _DropdownTile(
                label: 'Who can comment?',
                value: _constitution.commenting,
                items: const [
                  ('all-members', 'All Members'),
                  ('council-only', 'Council Only'),
                  ('sovereign-only', 'Sovereign Only'),
                ],
                onChanged: (v) => _update(() => _constitution = WorldConstitution(
                  admission: _constitution.admission,
                  minTier: _constitution.minTier,
                  requiredProfession: _constitution.requiredProfession,
                  posting: _constitution.posting,
                  commenting: v!,
                  contentTypes: _constitution.contentTypes,
                  entryFee: _constitution.entryFee,
                  allowAnonymous: _constitution.allowAnonymous,
                  requireApproval: _constitution.requireApproval,
                  language: _constitution.language,
                )),
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.md),
        _Section(
          title: 'Content Types',
          isDark: isDark,
          child: Wrap(
            spacing: VSpacing.sm,
            runSpacing: VSpacing.sm,
            children: [
              _ContentChip(
                label: 'Text',
                selected: _constitution.contentTypes.contains('text'),
                onTap: () => _update(() {
                  final types = List<String>.from(_constitution.contentTypes);
                  if (types.contains('text')) {
                    types.remove('text');
                  } else {
                    types.add('text');
                  }
                  _constitution = WorldConstitution(
                    admission: _constitution.admission,
                    minTier: _constitution.minTier,
                    requiredProfession: _constitution.requiredProfession,
                    posting: _constitution.posting,
                    commenting: _constitution.commenting,
                    contentTypes: types,
                    entryFee: _constitution.entryFee,
                    allowAnonymous: _constitution.allowAnonymous,
                    requireApproval: _constitution.requireApproval,
                    language: _constitution.language,
                  );
                }),
              ),
              _ContentChip(
                label: 'Image',
                selected: _constitution.contentTypes.contains('image'),
                onTap: () => _update(() {
                  final types = List<String>.from(_constitution.contentTypes);
                  if (types.contains('image')) {
                    types.remove('image');
                  } else {
                    types.add('image');
                  }
                  _constitution = WorldConstitution(
                    admission: _constitution.admission,
                    minTier: _constitution.minTier,
                    requiredProfession: _constitution.requiredProfession,
                    posting: _constitution.posting,
                    commenting: _constitution.commenting,
                    contentTypes: types,
                    entryFee: _constitution.entryFee,
                    allowAnonymous: _constitution.allowAnonymous,
                    requireApproval: _constitution.requireApproval,
                    language: _constitution.language,
                  );
                }),
              ),
              _ContentChip(
                label: 'Video',
                selected: _constitution.contentTypes.contains('video'),
                onTap: () => _update(() {
                  final types = List<String>.from(_constitution.contentTypes);
                  if (types.contains('video')) {
                    types.remove('video');
                  } else {
                    types.add('video');
                  }
                  _constitution = WorldConstitution(
                    admission: _constitution.admission,
                    minTier: _constitution.minTier,
                    requiredProfession: _constitution.requiredProfession,
                    posting: _constitution.posting,
                    commenting: _constitution.commenting,
                    contentTypes: types,
                    entryFee: _constitution.entryFee,
                    allowAnonymous: _constitution.allowAnonymous,
                    requireApproval: _constitution.requireApproval,
                    language: _constitution.language,
                  );
                }),
              ),
              _ContentChip(
                label: 'Poll',
                selected: _constitution.contentTypes.contains('poll'),
                onTap: () => _update(() {
                  final types = List<String>.from(_constitution.contentTypes);
                  if (types.contains('poll')) {
                    types.remove('poll');
                  } else {
                    types.add('poll');
                  }
                  _constitution = WorldConstitution(
                    admission: _constitution.admission,
                    minTier: _constitution.minTier,
                    requiredProfession: _constitution.requiredProfession,
                    posting: _constitution.posting,
                    commenting: _constitution.commenting,
                    contentTypes: types,
                    entryFee: _constitution.entryFee,
                    allowAnonymous: _constitution.allowAnonymous,
                    requireApproval: _constitution.requireApproval,
                    language: _constitution.language,
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: VSpacing.md),
        _Section(
          title: 'Advanced',
          isDark: isDark,
          child: Column(
            children: [
              _SwitchTile(
                label: 'Allow anonymous posts',
                value: _constitution.allowAnonymous,
                onChanged: (v) => _update(() => _constitution = WorldConstitution(
                  admission: _constitution.admission,
                  minTier: _constitution.minTier,
                  requiredProfession: _constitution.requiredProfession,
                  posting: _constitution.posting,
                  commenting: _constitution.commenting,
                  contentTypes: _constitution.contentTypes,
                  entryFee: _constitution.entryFee,
                  allowAnonymous: v,
                  requireApproval: _constitution.requireApproval,
                  language: _constitution.language,
                )),
              ),
              _SwitchTile(
                label: 'Require approval for new posts',
                value: _constitution.requireApproval,
                onChanged: (v) => _update(() => _constitution = WorldConstitution(
                  admission: _constitution.admission,
                  minTier: _constitution.minTier,
                  requiredProfession: _constitution.requiredProfession,
                  posting: _constitution.posting,
                  commenting: _constitution.commenting,
                  contentTypes: _constitution.contentTypes,
                  entryFee: _constitution.entryFee,
                  allowAnonymous: _constitution.allowAnonymous,
                  requireApproval: v,
                  language: _constitution.language,
                )),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget child;

  const _Section({required this.title, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainer,
        borderRadius: BorderRadius.circular(VRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: VFontWeight.semiBold,
              color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
            ),
          ),
          const SizedBox(height: VSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _RadioTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _RadioTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String label;
  final String value;
  final List<(String, String)> items;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        DropdownButton<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$2))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _ContentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ContentChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: VSpacing.md, vertical: VSpacing.xs),
        decoration: BoxDecoration(
          color: selected ? VColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(VRadius.pill),
          border: Border.all(
            color: selected ? VColors.primary : VColors.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: VFontSize.labelSm,
            fontWeight: selected ? VFontWeight.semiBold : VFontWeight.regular,
            color: selected ? VColors.primary : null,
          ),
        ),
      ),
    );
  }
}
