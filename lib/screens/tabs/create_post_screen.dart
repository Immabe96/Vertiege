import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post.dart';
import '../../models/world.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../../ui/inputs/v_input.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../utils/id_generator.dart';
import '../../ui/icons/v_icons.dart';
import '../../ui/buttons/v_button.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSovereignAnnouncement = false;
  bool _isSovereignDecree = false;
  bool _isPinned = false;
  String? _selectedWorldId;

  // Poll state
  String? _imagePath;
  final _picker = ImagePicker();
  bool _showPollBuilder = false;
  final _pollQuestionController = TextEditingController();
  final List<TextEditingController> _pollOptionControllers = [];
  bool _pollMultiChoice = false;

  @override
  void initState() {
    super.initState();
    // Start with 2 option fields
    _pollOptionControllers.add(TextEditingController());
    _pollOptionControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _pollQuestionController.dispose();
    for (final c in _pollOptionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPollOption() {
    if (_pollOptionControllers.length >= 5) return;
    setState(() {
      _pollOptionControllers.add(TextEditingController());
    });
  }

  void _removePollOption(int index) {
    if (_pollOptionControllers.length <= 2) return;
    setState(() {
      _pollOptionControllers[index].dispose();
      _pollOptionControllers.removeAt(index);
    });
  }

  Poll? _buildPoll() {
    if (!_showPollBuilder) return null;
    final question = _pollQuestionController.text.trim();
    if (question.isEmpty) return null;
    final options = <PollOption>[];
    for (final c in _pollOptionControllers) {
      final text = c.text.trim();
      if (text.isNotEmpty) {
        options.add(PollOption(id: generateId(), text: text));
      }
    }
    if (options.length < 2) return null;
    return Poll(
      question: question,
      options: options,
      isMultiChoice: _pollMultiChoice,
    );
  }

  Future<void> _pickImage() async {
    final result = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (result != null) setState(() => _imagePath = result.path);
  }

  void _insertFormatting(TextEditingController controller, String marker) {
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid) return;

    final selStart = selection.start;
    final selEnd = selection.end;

    String newText;
    int newCursorPos;

    if (selStart == selEnd) {
      // No selection — insert empty marker pair
      newText =
          '${text.substring(0, selStart)}$marker$marker${text.substring(selStart)}';
      newCursorPos = selStart + marker.length;
    } else {
      // Wrap selected text
      final selectedText = text.substring(selStart, selEnd);
      newText =
          '${text.substring(0, selStart)}$marker$selectedText$marker${text.substring(selEnd)}';
      newCursorPos = selEnd + marker.length * 2;
    }

    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: newCursorPos);
  }

  void _publish() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final worlds = ref
        .read(worldProvider)
        .worlds
        .values
        .where((world) => resident.joinedWorldIds.contains(world.id))
        .toList();
    final worldId =
        _selectedWorldId ?? (worlds.isNotEmpty ? worlds.first.id : null);
    if (worldId == null) return;

    final content = title.isEmpty ? body : '$title\n\n$body';
    final poll = _buildPoll();

    ref
        .read(postProvider.notifier)
        .addPost(
          worldId: worldId,
          residentId: resident.id,
          residentName: resident.name,
          residentAvatar: resident.avatarUrl,
          content: content,
          imageUri: _imagePath,
          tierValue: resident.tier.value,
          isAnnouncement: _isSovereignAnnouncement,
          isDecree: _isSovereignDecree,
          poll: poll,
        );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resident = ref.watch(residentProvider).resident;
    final worlds = ref
        .watch(worldProvider)
        .worlds
        .values
        .where((world) => resident?.joinedWorldIds.contains(world.id) ?? false)
        .toList();
    final selectedWorld = worlds.firstWhere(
      (world) => world.id == _selectedWorldId,
      orElse: () => worlds.isNotEmpty
          ? worlds.first
          : const World(
              id: 'nexus',
              name: 'Nexus',
              type: WorldType.wealth,
              description: '',
              sovereignId: '',
              sovereignName: '',
            ),
    );

    return Scaffold(
      backgroundColor: isDark ? VColors.surfaceDark : VColors.surface,
      appBar: AppBar(
        backgroundColor: (isDark ? VColors.surfaceDark : VColors.surface)
            .withValues(alpha: 0.8),
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? VColors.onSurfaceVariantDark : VColors.onSurfaceVariant,
          ),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'Vertiege',
          style: TextStyle(
            fontFamily: AppFont.headline,
            fontSize: FontSizes.headlineLg,
            fontWeight: FontWeights.bold,
            color: VColors.tertiary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.md),
            child: VButton(
              label: 'PUBLISH',
              onPressed: worlds.isEmpty ? null : _publish,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.marginMobile),
        child: Column(
          children: [
            const SizedBox(height: Spacing.xl),

            // World selector
            if (worlds.isNotEmpty)
              _Card(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark
                            ? VColors.secondaryContainerDark
                            : VColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: const Icon(
                        Icons.language,
                        color: VColors.tertiary,
                        size: IconSizes.sm,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                        Expanded(
                      child: FSelect<String>.rich(
                        format: (value) => selectedWorld.name,
                        control: FSelectControl.lifted(
                          value: selectedWorld.id,
                          onChange: (v) {
                            if (v != null) setState(() {
                              _selectedWorldId = v;
                              _isSovereignAnnouncement = false;
                              _isSovereignDecree = false;
                            });
                          },
                        ),
                        children: worlds.map((world) => FSelectItem<String>(
                          value: world.id,
                          title: Text(world.name, overflow: TextOverflow.ellipsis),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              )
            else
              _Card(
                padding: EdgeInsets.all(Spacing.lg),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: isDark
                          ? VColors.onSurfaceVariantDark
                          : VColors.onSurfaceVariant,
                    ),
                    SizedBox(width: Spacing.md),
                    Expanded(
                      child: Text(
                        'Join a world before publishing.',
                        style: TextStyle(
                          color: isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant,
                          fontSize: FontSizes.bodyMd,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: Spacing.lg),

            // Announcement toggle (Council+ only)
            Consumer(
              builder: (context, ref, _) {
                final resident = ref.watch(residentProvider).resident;
                final isCouncil =
                    resident != null &&
                    resident.worldStandings[selectedWorld.id]?.rep != null &&
                    resident.worldStandings[selectedWorld.id]!.rep >= 5000;
                final isSov =
                    resident != null &&
                    resident.id == selectedWorld.sovereignId;
                if (!isCouncil && !isSov) return const SizedBox.shrink();

                return _Card(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Row(
                    children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: VColors.tertiary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(RadiusTokens.md),
                          ),
                          child: const Icon(
                            Icons.stars,
                            color: VColors.tertiary,
                            size: IconSizes.lg,
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Announcement',
                                style: TextStyle(
                                  fontSize: FontSizes.headlineMd,
                                  fontWeight: FontWeights.semiBold,
                                  color: VColors.tertiary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Pin to the priority feed of all members.',
                                style: TextStyle(
                                  fontSize: FontSizes.bodyMd,
                                  color: isDark
                                      ? VColors.onSurfaceVariantDark
                                      : VColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isSovereignAnnouncement,
                          onChanged: (v) =>
                              setState(() => _isSovereignAnnouncement = v),
                          thumbColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return VColors.onPrimary;
                            }
                            return isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant;
                          }),
                          trackColor: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return VColors.tertiary.withValues(alpha: 0.4);
                            }
                            return (isDark
                                ? VColors.onSurfaceVariantDark
                                : VColors.onSurfaceVariant).withValues(
                                alpha: 0.2,
                              );
                          }),
                        ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.lg),

            // Pin Post toggle (tier-gated)
            Consumer(
              builder: (context, ref, _) {
                final resident = ref.watch(residentProvider).resident;
                final pinLimit = resident?.postPinLimit ?? 0;
                if (pinLimit <= 0) return const SizedBox.shrink();

                return _Card(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: VColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(RadiusTokens.md),
                        ),
                        child: const Icon(
                          Icons.push_pin,
                          color: VColors.primary,
                          size: IconSizes.lg,
                        ),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pin Post',
                              style: TextStyle(
                                fontSize: FontSizes.headlineMd,
                                fontWeight: FontWeights.semiBold,
                                color: VColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pin to top of the feed.',
                              style: TextStyle(
                                fontSize: FontSizes.bodyMd,
                                color: isDark
                                    ? VColors.onSurfaceVariantDark
                                    : VColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPinned,
                        onChanged: (v) => setState(() => _isPinned = v),
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return VColors.onPrimary;
                          }
                          return isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant;
                        }),
                        trackColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return VColors.primary.withValues(alpha: 0.4);
                          }
                          return (isDark
                              ? VColors.onSurfaceVariantDark
                              : VColors.onSurfaceVariant).withValues(
                              alpha: 0.2,
                            );
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.lg),

            // Editor
            _Card(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VInput(
                    controller: _titleController,
                    hint: 'Title of your dispatch...',
                  ),
                  const SizedBox(height: Spacing.lg),
                  // Formatting bar
                  Row(
                    children: [
                      _FormatButton(
                        icon: Icons.format_bold,
                        label: 'B',
                        onTap: () => _insertFormatting(_bodyController, '**'),
                      ),
                      const SizedBox(width: Spacing.xs),
                      _FormatButton(
                        icon: Icons.format_italic,
                        label: 'I',
                        onTap: () => _insertFormatting(_bodyController, '*'),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.sm),
                  VInput(
                    controller: _bodyController,
                    hint: 'Share your insights with the Nexus...',
                    maxLines: 8,
                  ),
                ],
              ),
            ),

            const SizedBox(height: Spacing.lg),

            // Poll builder
            if (_showPollBuilder) ...[
              const SizedBox(height: Spacing.lg),
              _PollBuilder(
                questionController: _pollQuestionController,
                optionControllers: _pollOptionControllers,
                isMultiChoice: _pollMultiChoice,
                onToggleMultiChoice: () =>
                    setState(() => _pollMultiChoice = !_pollMultiChoice),
                onAddOption: _addPollOption,
                onRemoveOption: _removePollOption,
                onRemove: () => setState(() => _showPollBuilder = false),
              ),
            ],

            // Quick attach bar
            Row(
              children: [
                _AttachChip(
                  icon: Icons.image,
                  label: _imagePath != null ? 'IMAGE READY' : 'UPLOAD IMAGE',
                  onTap: _pickImage,
                  selected: _imagePath != null,
                ),
                const SizedBox(width: Spacing.sm),
                _AttachChip(
                  icon: _showPollBuilder ? Icons.poll : Icons.poll_outlined,
                  label: _showPollBuilder ? 'EDIT POLL' : 'ADD POLL',
                  onTap: () => setState(() => _showPollBuilder = true),
                  selected: _showPollBuilder,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  const _AttachChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: selected
              ? VColors.tertiary.withValues(alpha: 0.15)
              : (isDark ? VColors.glassBackgroundDark : VColors.glassBackground),
          borderRadius: BorderRadius.circular(RadiusTokens.full),
          border: Border.all(
            color: selected
                ? VColors.tertiary.withValues(alpha: 0.4)
                : (isDark ? VColors.glassBorderDark : VColors.glassBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: IconSizes.sm,
              color: selected
                  ? VColors.tertiary
                  : (isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: FontSizes.labelSm,
                fontWeight: FontWeights.semiBold,
                color: selected
                    ? VColors.tertiary
                    : (isDark
                        ? VColors.onSurfaceVariantDark
                        : VColors.onSurfaceVariant),
                letterSpacing: LetterSpacing.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PollBuilder extends StatelessWidget {
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final bool isMultiChoice;
  final VoidCallback onToggleMultiChoice;
  final VoidCallback onAddOption;
  final void Function(int index) onRemoveOption;
  final VoidCallback onRemove;

  const _PollBuilder({
    required this.questionController,
    required this.optionControllers,
    required this.isMultiChoice,
    required this.onToggleMultiChoice,
    required this.onAddOption,
    required this.onRemoveOption,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _Card(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
            const Icon(
              Icons.poll,
              size: IconSizes.md,
              color: VColors.tertiary,
            ),
            const SizedBox(width: Spacing.sm),
            const Expanded(
              child: Text(
                'Poll',
                style: TextStyle(
                  fontSize: FontSizes.headlineMd,
                  fontWeight: FontWeights.semiBold,
                  color: VColors.onSurface,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(VIcons.x, size: IconSizes.md),
              onPressed: onRemove,
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Question field
          VInput(controller: questionController, hint: 'Poll question...'),
          const SizedBox(height: Spacing.md),

          // Options
          ...optionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index < optionControllers.length - 1 ? Spacing.sm : 0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: VInput(
                      controller: controller,
                      hint: 'Option ${index + 1}...',
                    ),
                  ),
                  if (optionControllers.length > 2)
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle_outline,
                          size: IconSizes.md,
                        ),
                        onPressed: () => onRemoveOption(index),
                        color: VColors.error,
                      ),
                ],
              ),
            );
          }),

          const SizedBox(height: Spacing.sm),

          // Add Option button
          if (optionControllers.length < 5)
            TextButton.icon(
              onPressed: onAddOption,
              icon: const Icon(VIcons.plus, size: IconSizes.sm),
              label: const Text(
                'Add Option',
                style: TextStyle(
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.semiBold,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: VColors.primary),
            ),

          const SizedBox(height: Spacing.sm),

          // Multi-choice toggle
          Row(
            children: [
              Icon(
                Icons.checklist,
                size: IconSizes.sm,
                color: isDark
                    ? VColors.onSurfaceVariantDark
                    : VColors.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.sm),
              const Expanded(
                child: Text(
                  'Allow multiple choices',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMd,
                    color: VColors.onSurface,
                  ),
                ),
              ),
              Switch(
                value: isMultiChoice,
                onChanged: (_) => onToggleMultiChoice(),
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return VColors.onPrimary;
                  }
                  return isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant;
                }),
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return VColors.tertiary.withValues(alpha: 0.4);
                  }
                  return (isDark
                      ? VColors.onSurfaceVariantDark
                      : VColors.onSurfaceVariant).withValues(alpha: 0.2);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FormatButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? VColors.surfaceContainerHighDark : VColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(RadiusTokens.md),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: FontSizes.bodyMd,
              fontWeight: label == 'B' ? FontWeights.bold : FontWeights.regular,
              fontStyle: label == 'I' ? FontStyle.italic : FontStyle.normal,
              color: isDark
                  ? VColors.onSurfaceVariantDark
                  : VColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _Card({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? VColors.surfaceContainerDark : VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(RadiusTokens.lg),
        border: Border.all(
          color: isDark ? VColors.outlineVariantDark : VColors.outlineVariant,
        ),
      ),
      child: child,
    );
  }
}
