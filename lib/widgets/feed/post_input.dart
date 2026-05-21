import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/permission_service.dart';
import '../../services/storage_service.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../../state/world_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/design_system.dart';
import '../shared/image_picker_widget.dart';
import '../core/xp_toast.dart';

class PostInput extends ConsumerStatefulWidget {
  final String worldId;
  final String? sovereignId;
  final bool showWorldSelector;

  const PostInput({
    super.key,
    required this.worldId,
    this.sovereignId,
    this.showWorldSelector = false,
  });

  @override
  ConsumerState<PostInput> createState() => _PostInputState();
}

class _ImagePreview extends StatelessWidget {
  final String uri;
  final double height;
  final double width;

  const _ImagePreview({
    required this.uri,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (uri.startsWith('http')) {
      return Image.network(
        uri,
        height: height,
        width: width,
        fit: BoxFit.cover,
      );
    }
    return Image.file(
      File(uri),
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        height: height,
        width: width,
        color: isDark ? VColors.surfaceContainerHighestDark : VColors.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.broken_image, color: isDark ? VColors.onSurfaceVariantDark : VColors.outline),
      ),
    );
  }
}

class _PostInputState extends ConsumerState<PostInput>
    with SingleTickerProviderStateMixin {
  static const int _maxChars = 500;
  static const int _warnChars = 400;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _suggestionOverlay;
  String? _imageUri;
  bool _isAnnouncement = false;
  bool _sent = false;
  String? _selectedWorldId;
  late final AnimationController _sendAnim;
  late final Animation<double> _sendScale;

  bool _hasDraft = false;

  // Autocomplete state
  String _suggestionType = ''; // '@' or '#'
  List<String> _filteredSuggestions = [];
  int _triggerPosition = -1;

  @override
  void initState() {
    super.initState();
    _sendAnim = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _sendScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _sendAnim, curve: Curves.easeInOut));

    _selectedWorldId = widget.showWorldSelector ? null : widget.worldId;
    _loadDraft();
  }

  @override
  void dispose() {
    _hideSuggestionsOverlay();
    _controller.dispose();
    _focusNode.dispose();
    _sendAnim.dispose();
    super.dispose();
  }

  // ── Autocomplete ────────────────────────────────────────────

  static const List<String> _trendingHashtags = [
    'vertiege',
    'design',
    'nexus',
    'sovereign',
    'prestige',
    'worlds',
    'realm',
    'flutter',
    'council',
    'quest',
  ];

  void _onTextChanged(String text) {
    _detectTrigger(text);
    setState(() {});
  }

  void _detectTrigger(String text) {
    final cursorPos = _controller.selection.baseOffset;
    if (cursorPos < 0) {
      _hideSuggestionsOverlay();
      return;
    }

    // Look backwards from cursor for @ or #
    String beforeCursor = text.substring(0, cursorPos);
    final mentionMatch = RegExp(r'@(\w*)$').firstMatch(beforeCursor);
    final hashtagMatch = RegExp(r'#(\w*)$').firstMatch(beforeCursor);

    if (mentionMatch != null) {
      final query = mentionMatch.group(1) ?? '';
      _triggerPosition = mentionMatch.start;
      _suggestionType = '@';
      _getMentionSuggestions(query);
    } else if (hashtagMatch != null) {
      final query = hashtagMatch.group(1) ?? '';
      _triggerPosition = hashtagMatch.start;
      _suggestionType = '#';
      _getHashtagSuggestions(query);
    } else {
      _hideSuggestionsOverlay();
      return;
    }
  }

  void _getMentionSuggestions(String query) {
    // Gather unique resident names from posts and current resident
    final postState = ref.read(postProvider);
    final names = <String>{};
    final resident = ref.read(residentProvider).resident;
    if (resident != null) names.add(resident.name);
    for (final post in postState.posts) {
      names.add(post.residentName);
    }

    _filteredSuggestions =
        names
            .where((n) => n.toLowerCase().contains(query.toLowerCase()))
            .toList()
          ..sort();

    if (_filteredSuggestions.isNotEmpty) {
      _showSuggestionsOverlay();
    } else {
      _hideSuggestionsOverlay();
    }
  }

  void _getHashtagSuggestions(String query) {
    final postState = ref.read(postProvider);
    // Gather existing hashtags from all posts
    final tags = <String>{};
    tags.addAll(_trendingHashtags);
    for (final post in postState.posts) {
      tags.addAll(post.hashtags);
    }

    _filteredSuggestions =
        tags
            .where((t) => t.toLowerCase().contains(query.toLowerCase()))
            .toList()
          ..sort();

    if (_filteredSuggestions.isNotEmpty) {
      _showSuggestionsOverlay();
    } else {
      _hideSuggestionsOverlay();
    }
  }

  void _showSuggestionsOverlay() {
    _hideSuggestionsOverlay();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    _suggestionOverlay = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(RadiusTokens.md),
            color: isDark ? VColors.surfaceContainerHighestDark : VColors.surfaceContainerHighest,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _filteredSuggestions[index];
                  return InkWell(
                    onTap: () => _insertSuggestion(suggestion),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.sm + 4,
                      ),
                      child: Text(
                        '$_suggestionType$suggestion',
                        style: TextStyle(
                          fontSize: FontSizes.bodyMd,
                          color: isDark ? VColors.onSurfaceDark : VColors.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_suggestionOverlay!);
  }

  void _hideSuggestionsOverlay() {
    _suggestionOverlay?.remove();
    _suggestionOverlay = null;
    _filteredSuggestions = [];
    _triggerPosition = -1;
  }

  void _insertSuggestion(String suggestion) {
    final text = _controller.text;
    final cursorPos = _controller.selection.baseOffset;
    final before = text.substring(0, _triggerPosition);
    final after = text.substring(cursorPos);
    final newText = '$before$_suggestionType$suggestion $after';
    final newCursor =
        _triggerPosition + suggestion.length + 2; // +2 for @/# and space

    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: newCursor);
    _hideSuggestionsOverlay();
    _focusNode.requestFocus();
  }

  // ── Drafts ─────────────────────────────────────────────────

  String get _draftKey {
    final residentId = ref.read(residentProvider).resident?.id ?? 'anon';
    final worldId = _selectedWorldId ?? widget.worldId;
    return '@post_draft:$residentId:$worldId';
  }

  Future<void> _loadDraft() async {
    final raw = await StorageService.getString(_draftKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final text = data['text'] as String? ?? '';
      final imageUri = data['imageUri'] as String?;
      if (text.isNotEmpty) {
        setState(() {
          _hasDraft = true;
          _controller.text = text;
          _imageUri = imageUri;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _imageUri == null) return;
    final data = jsonEncode({'text': text, 'imageUri': _imageUri});
    await StorageService.setString(_draftKey, data);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _discardDraft() async {
    await StorageService.remove(_draftKey);
    setState(() {
      _hasDraft = false;
      _controller.clear();
      _imageUri = null;
    });
  }

  void _continueDraft() {
    setState(() => _hasDraft = false);
  }

  // ── Submit ─────────────────────────────────────────────────

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    final targetWorldId = _selectedWorldId ?? widget.worldId;
    final imageUri = _imageUri;
    final isAnnouncement = _isAnnouncement;

    _controller.clear();
    _sendAnim.forward(from: 0);
    XpToast.show(context, amount: 15);
    setState(() {
      _imageUri = null;
      _isAnnouncement = false;
      _sent = true;
      _hasDraft = false;
    });
    await StorageService.remove(_draftKey);

    try {
      await ref
          .read(postProvider.notifier)
          .addPost(
            worldId: targetWorldId,
            residentId: resident.id,
            residentName: resident.name,
            residentAvatar: resident.avatarUrl,
            content: content,
            imageUri: imageUri,
            tierValue: resident.tier.value,
            isAnnouncement: isAnnouncement,
          );
    } catch (_) {
      if (mounted) {
        setState(() => _sent = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish post. Please try again.'),
          ),
        );
      }
      return;
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _sent = false);
    });
  }

  // ── Character count ────────────────────────────────────────

  Color _charCountColor(int length) {
    if (length >= _maxChars) return VColors.error;
    if (length >= _warnChars) return VColors.warning;
    return Theme.of(context).colorScheme.outline;
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resident = ref.watch(residentProvider).resident;
    final allWorlds = ref.watch(worldProvider).worlds;
    final worlds = allWorlds.values
        .where((w) => resident?.joinedWorldIds.contains(w.id) ?? false)
        .toList();
    final canAnnounce =
        resident != null &&
        WorldPermissions.canAnnounce(
          resident,
          widget.worldId,
          widget.sovereignId,
        );

    final charLength = _controller.text.length;
    final charColor = _charCountColor(charLength);

    return Card(
      margin: const EdgeInsets.all(Spacing.md),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Draft banner ─────────────────────────────────
            if (_hasDraft)
              Container(
                margin: const EdgeInsets.only(bottom: Spacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(RadiusTokens.chip),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.drafts,
                      size: IconSizes.sm,
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        'You have a saved draft. Continue?',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _discardDraft,
                      child: Text(
                        'Discard',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: FontSizes.caption,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _continueDraft,
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: FontSizes.caption,
                          fontWeight: FontWeights.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── World selector (Nexus) ─────────────────────────
            if (widget.showWorldSelector && worlds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedWorldId,
                  isDense: true,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.input),
                    ),
                    labelText: 'Post to',
                    labelStyle: theme.textTheme.labelSmall,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.public,
                            size: IconSizes.sm,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: Spacing.xs),
                          Text('My Feed', style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ),
                    ...worlds.map(
                      (world) => DropdownMenuItem<String>(
                        value: world.id,
                        child: Text(
                          world.name,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedWorldId = value),
                ),
              ),

            // ── Announcement toggle ───────────────────────────
            if (canAnnounce)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: InkWell(
                  borderRadius: BorderRadius.circular(RadiusTokens.chip),
                  onTap: () =>
                      setState(() => _isAnnouncement = !_isAnnouncement),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.md,
                      vertical: Spacing.xs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(RadiusTokens.chip),
                      color: _isAnnouncement
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.campaign,
                          size: IconSizes.sm,
                          color: _isAnnouncement
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          'Announcement',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: _isAnnouncement
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                            fontWeight: FontWeights.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Text input + actions ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CompositedTransformTarget(
                        link: _layerLink,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          maxLines: 3,
                          minLines: 1,
                          maxLength: _maxChars,
                          buildCounter:
                              (
                                context, {
                                required currentLength,
                                required isFocused,
                                maxLength,
                              }) => null,
                          decoration: const InputDecoration(
                            hintText: "What's on your mind?",
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                              vertical: Spacing.sm,
                            ),
                          ),
                          onChanged: _onTextChanged,
                        ),
                      ),
                      // Character count
                      Padding(
                        padding: const EdgeInsets.only(
                          top: Spacing.xs,
                          left: Spacing.xs,
                        ),
                        child: AnimatedDefaultTextStyle(
                          duration: AnimDurations.fast,
                          style: theme.textTheme.labelSmall!.copyWith(
                            color: charColor,
                            fontWeight: charLength >= _warnChars
                                ? FontWeights.bold
                                : FontWeights.regular,
                          ),
                          child: Text('$charLength/$_maxChars'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Column(
                  children: [
                    // Save draft button
                    IconButton(
                      icon: const Icon(Icons.drafts_outlined),
                      onPressed:
                          _controller.text.trim().isNotEmpty ||
                              _imageUri != null
                          ? _saveDraft
                          : null,
                      tooltip: 'Save draft',
                      iconSize: IconSizes.md,
                      color: theme.colorScheme.outline,
                    ),
                    // Send button
                    ScaleTransition(
                      scale: _sendScale,
                      child: IconButton(
                        icon: Icon(_sent ? Icons.check : Icons.send),
                        onPressed: _sent || charLength > _maxChars
                            ? null
                            : _submit,
                        color: _sent ? VColors.success : theme.colorScheme.primary,
                        iconSize: IconSizes.md,
                      ),
                    ),
                    ImagePickerWidget(
                      onImageSelected: (uri) => setState(() => _imageUri = uri),
                    ),
                  ],
                ),
              ],
            ),

            // ── Image preview ──────────────────────────────────
            if (_imageUri != null) ...[
              const SizedBox(height: Spacing.sm),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(RadiusTokens.chip),
                    child: _ImagePreview(
                      uri: _imageUri!,
                      height: 80,
                      width: 80,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _imageUri = null),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
