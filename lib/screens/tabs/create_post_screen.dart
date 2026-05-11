import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post.dart';
import '../../theme/colors.dart';
import '../../theme/design_system.dart';
import '../../widgets/core/glass_panel.dart';
import '../../widgets/core/ghost_input.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../utils/id_generator.dart';

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
    final result = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
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
      newText = '${text.substring(0, selStart)}$marker$marker${text.substring(selStart)}';
      newCursorPos = selStart + marker.length;
    } else {
      // Wrap selected text
      final selectedText = text.substring(selStart, selEnd);
      newText = '${text.substring(0, selStart)}$marker$selectedText$marker${text.substring(selEnd)}';
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

    final worlds = ref.read(worldProvider).worlds.values.toList();
    final worldId = worlds.isNotEmpty ? worlds.first.id : 'nexus';

    final content = title.isEmpty ? body : '$title\n\n$body';
    final poll = _buildPoll();

    ref.read(postProvider.notifier).addPost(
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

    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final worlds = ref.watch(worldProvider).worlds.values.toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.8),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.inkSecondary),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          'Vertiege',
          style: TextStyle(
            fontFamily: AppFont.headline,
            fontSize: FontSizes.headlineLg,
            fontWeight: FontWeights.bold,
            color: AppColors.tertiary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Spacing.md),
            child: FilledButton(
              onPressed: _publish,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tertiary,
                foregroundColor: AppColors.onTertiary,
              ),
              child: const Text('PUBLISH'),
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
              GlassPanel(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius: BorderRadius.circular(RadiusTokens.md),
                      ),
                      child: const Icon(Icons.language, color: AppColors.tertiary, size: IconSizes.sm),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Text(
                        worlds.first.name,
                        style: const TextStyle(
                          fontSize: FontSizes.headlineMd,
                          fontWeight: FontWeights.semiBold,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more, color: AppColors.inkSecondary),
                  ],
                ),
              ),

            const SizedBox(height: Spacing.lg),

            // Announcement toggle (Council+ only)
            Consumer(
              builder: (context, ref, _) {
                final resident = ref.watch(residentProvider).resident;
                final worlds = ref.watch(worldProvider).worlds;
                final selectedWorld = worlds.values.firstOrNull;
                final isCouncil = resident != null &&
                    selectedWorld != null &&
                    resident.worldStandings[selectedWorld.id]?.rep != null &&
                    resident.worldStandings[selectedWorld.id]!.rep >= 5000;
                final isSov = resident != null &&
                    selectedWorld != null &&
                    resident.id == selectedWorld.sovereignId;
                if (!isCouncil && !isSov) return const SizedBox.shrink();

                return GlassPanel(
                  padding: const EdgeInsets.all(Spacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(RadiusTokens.md),
                        ),
                        child: const Icon(Icons.stars, color: AppColors.tertiary, size: IconSizes.lg),
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
                                color: AppColors.tertiary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pin to the priority feed of all members.',
                              style: TextStyle(
                                fontSize: FontSizes.bodyMd,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isSovereignAnnouncement,
                        onChanged: (v) => setState(() => _isSovereignAnnouncement = v),
                        activeThumbColor: AppColors.tertiary,
                        activeTrackColor: AppColors.tertiary.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: Spacing.lg),

            // Sovereign Decree toggle (only visible to sovereign)
            Consumer(
              builder: (context, ref, _) {
                final resident = ref.watch(residentProvider).resident;
                final worlds = ref.watch(worldProvider).worlds;
                final selectedWorld = worlds.values.firstOrNull;
                final isSovereign = resident != null &&
                    selectedWorld != null &&
                    resident.id == selectedWorld.sovereignId;

                if (!isSovereign) return const SizedBox.shrink();

                return Column(
                  children: [
                    GlassPanel(
                      padding: const EdgeInsets.all(Spacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.tertiary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(RadiusTokens.md),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.tertiary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.auto_awesome, color: AppColors.tertiary, size: IconSizes.lg),
                          ),
                          const SizedBox(width: Spacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Sovereign Decree',
                                      style: TextStyle(
                                        fontSize: FontSizes.headlineMd,
                                        fontWeight: FontWeights.semiBold,
                                        color: AppColors.tertiary,
                                      ),
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Spacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.tertiary, AppColors.tertiaryFixedDim],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(RadiusTokens.pill),
                                      ),
                                      child: const Text(
                                        'SOVEREIGN ONLY',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeights.bold,
                                          color: AppColors.onTertiary,
                                          letterSpacing: LetterSpacing.label,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Golden-bordered, glowing decree pinned for 24 hours.',
                                  style: TextStyle(
                                    fontSize: FontSizes.bodyMd,
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isSovereignDecree,
                            onChanged: (v) => setState(() => _isSovereignDecree = v),
                            activeThumbColor: AppColors.tertiary,
                            activeTrackColor: AppColors.tertiary.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                  ],
                );
              },
            ),

            // Editor
            GlassPanel(
              padding: const EdgeInsets.all(Spacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GhostInput(
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
                  GhostInput(
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
                onToggleMultiChoice: () => setState(() => _pollMultiChoice = !_pollMultiChoice),
                onAddOption: _addPollOption,
                onRemoveOption: _removePollOption,
                onRemove: () => setState(() => _showPollBuilder = false),
              ),
            ],

            // Quick attach bar
            Row(
              children: [
                _AttachChip(icon: Icons.image, label: _imagePath != null ? 'IMAGE READY' : 'UPLOAD IMAGE', onTap: _pickImage, selected: _imagePath != null),
                const SizedBox(width: Spacing.sm),
                _AttachChip(icon: Icons.description, label: 'DOCUMENT', onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document upload coming soon')));
                }),
                const SizedBox(width: Spacing.sm),
                _AttachChip(icon: Icons.link, label: 'ADD LINK', onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link attachment coming soon')));
                }),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm + 2),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.tertiary.withValues(alpha: 0.15)
              : AppColors.glassBackground,
          borderRadius: BorderRadius.circular(RadiusTokens.full),
          border: Border.all(
            color: selected ? AppColors.tertiary.withValues(alpha: 0.4) : AppColors.glassBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: IconSizes.sm,
                color: selected ? AppColors.tertiary : AppColors.inkSecondary),
            const SizedBox(width: Spacing.sm),
            Text(
              label,
              style: TextStyle(
                fontSize: FontSizes.labelSm,
                fontWeight: FontWeights.semiBold,
                color: selected ? AppColors.tertiary : AppColors.inkSecondary,
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
    return GlassPanel(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.poll, size: IconSizes.md, color: AppColors.tertiary),
              const SizedBox(width: Spacing.sm),
              const Expanded(
                child: Text(
                  'Poll',
                  style: TextStyle(
                    fontSize: FontSizes.headlineMd,
                    fontWeight: FontWeights.semiBold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: IconSizes.md),
                onPressed: onRemove,
                color: AppColors.inkMuted,
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // Question field
          GhostInput(
            controller: questionController,
            hint: 'Poll question...',
          ),
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
                    child: GhostInput(
                      controller: controller,
                      hint: 'Option ${index + 1}...',
                    ),
                  ),
                  if (optionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: IconSizes.md),
                      onPressed: () => onRemoveOption(index),
                      color: AppColors.error,
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
              icon: const Icon(Icons.add_circle_outline, size: IconSizes.sm),
              label: const Text(
                'Add Option',
                style: TextStyle(
                  fontSize: FontSizes.labelSm,
                  fontWeight: FontWeights.semiBold,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),

          const SizedBox(height: Spacing.sm),

          // Multi-choice toggle
          Row(
            children: [
              const Icon(Icons.checklist, size: IconSizes.sm, color: AppColors.inkSecondary),
              const SizedBox(width: Spacing.sm),
              const Expanded(
                child: Text(
                  'Allow multiple choices',
                  style: TextStyle(
                    fontSize: FontSizes.bodyMd,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Switch(
                value: isMultiChoice,
                onChanged: (_) => onToggleMultiChoice(),
                activeThumbColor: AppColors.tertiary,
                activeTrackColor: AppColors.tertiary.withValues(alpha: 0.4),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.glassBackground,
          borderRadius: BorderRadius.circular(RadiusTokens.md),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: FontSizes.bodyMd,
              fontWeight: label == 'B' ? FontWeights.bold : FontWeights.regular,
              fontStyle: label == 'I' ? FontStyle.italic : FontStyle.normal,
              color: AppColors.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
