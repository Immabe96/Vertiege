import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/resident.dart';
import '../../theme/v_tokens.dart';
import '../../theme/v_colors.dart';
import '../../utils/haptics.dart';
import '../../ui/icons/v_icons.dart';
import '../../ui/buttons/v_button.dart';

class EditProfileSheet extends StatefulWidget {
  final Resident resident;
  final void Function({String? name, String? bio, String? avatarPath, String? profession}) onSave;

  const EditProfileSheet({super.key, required this.resident, required this.onSave});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  final _nameFocus = FocusNode();
  final _bioFocus = FocusNode();
  final _picker = ImagePicker();
  File? _editAvatarFile;
  late String _selectedProfession;
  bool _saving = false;

  static const _professions = [
    '',
    'Aviation',
    'Medical',
    'Finance',
    'Legal',
    'Technology',
    'Engineering',
    'Arts',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.resident.name);
    _bioController = TextEditingController(text: widget.resident.bio);
    _selectedProfession = widget.resident.profession ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _nameFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              VSpacing.lg,
              VSpacing.sm,
              VSpacing.lg,
              VSpacing.xl,
            ),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: VSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                ),
              ),
              Text(
                'Edit Profile',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                  fontWeight: VFontWeight.bold,
                ),
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                'Customize how others see you in the worlds.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.outline,
                ),
              ),
              const SizedBox(height: VSpacing.lg),
              _sectionHeader(ctx, 'Profile Photo'),
              const SizedBox(height: VSpacing.sm),
              _buildAvatarPicker(ctx),
              const SizedBox(height: VSpacing.lg),
              _sectionHeader(ctx, 'Display name'),
              const SizedBox(height: VSpacing.sm),
              TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 100,
                onSubmitted: (_) => _bioFocus.requestFocus(),
                decoration: InputDecoration(
                  hintText: 'Your display name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VRadius.lg),
                  ),
                  prefixIcon: const Icon(VIcons.user),
                  filled: true,
                  counterText: '',
                ),
              ),
              const SizedBox(height: VSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionHeader(ctx, 'Bio'),
                  Text(
                    '${_bioController.text.length}/160',
                    style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                      color: _bioController.text.length >= 160
                          ? VColors.error
                          : Theme.of(ctx).colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VSpacing.sm),
              TextField(
                controller: _bioController,
                focusNode: _bioFocus,
                maxLines: 3,
                maxLength: 160,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'A few words about yourself...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(VRadius.lg),
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 56),
                    child: Icon(VIcons.edit),
                  ),
                  filled: true,
                  counterText: '',
                ),
              ),
              const SizedBox(height: VSpacing.lg),
              _sectionHeader(ctx, 'Profession'),
              const SizedBox(height: VSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _professions.map((p) {
                  final isSel = _selectedProfession == p;
                  return ChoiceChip(
                    label: Text(p.isEmpty ? 'None' : p),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedProfession = p),
                    selectedColor: VColors.primary,
                    labelStyle: TextStyle(
                      color: isSel
                          ? VColors.onPrimary
                          : Theme.of(ctx).colorScheme.onSurfaceVariant,
                      fontSize: VFontSize.bodyMd,
                    ),
                    backgroundColor:
                        Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    side: BorderSide(
                      color: isSel
                          ? VColors.primary
                          : Theme.of(ctx).colorScheme.outlineVariant,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: VSpacing.xs),
              Text(
                'Self-declared — verification coming soon.',
                style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.outline,
                ),
              ),
              const SizedBox(height: VSpacing.xl),
              VButton(
                label: 'Save Changes',
                onPressed: _save,
                icon: const Icon(VIcons.badgeCheck),
                isLoading: _saving,
              ),
              const SizedBox(height: VSpacing.sm),
              VButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
                variant: ButtonVariant.text,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarPicker(BuildContext ctx) {
    return Row(
      children: [
        Expanded(
          child: _pickButton(
            ctx,
            Icons.camera_alt_outlined,
            'Camera',
            () async {
              final picked = await _picker.pickImage(
                source: ImageSource.camera,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 85,
              );
              if (picked != null) setState(() => _editAvatarFile = File(picked.path));
            },
          ),
        ),
        const SizedBox(width: VSpacing.sm),
        Expanded(
          child: _pickButton(
            ctx,
            Icons.photo_library_outlined,
            'Gallery',
            () async {
              final picked = await _picker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 512,
                maxHeight: 512,
                imageQuality: 85,
              );
              if (picked != null) setState(() => _editAvatarFile = File(picked.path));
            },
          ),
        ),
      ],
    );
  }

  Widget _pickButton(
    BuildContext ctx,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final t = Theme.of(ctx);
    return Material(
      color: t.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(VRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: VSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: VColors.primary, size: 28),
              const SizedBox(height: VSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: t.colorScheme.onSurfaceVariant,
                  fontSize: VFontSize.bodyMd,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: VFontWeight.bold,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty || name.length < 2) {
      Haptics.heavy();
      _nameFocus.requestFocus();
      return;
    }

    setState(() => _saving = true);

    final cloudAvatar = _editAvatarFile?.path;

    widget.onSave(
      name: name,
      bio: _bioController.text.trim(),
      avatarPath: cloudAvatar,
      profession: _selectedProfession.isEmpty ? null : _selectedProfession,
    );

    Navigator.of(context).pop();
  }
}

void showEditProfileSheet(
  BuildContext context,
  Resident resident, {
  required void Function({String? name, String? bio, String? avatarPath, String? profession}) onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(VRadius.xl),
      ),
    ),
    builder: (sheetContext) => EditProfileSheet(resident: resident, onSave: onSave),
  );
}
