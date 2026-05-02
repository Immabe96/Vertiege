import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/post_provider.dart';
import '../../state/resident_provider.dart';
import '../shared/image_picker_widget.dart';

class PostInput extends ConsumerStatefulWidget {
  final String worldId;

  const PostInput({super.key, required this.worldId});

  @override
  ConsumerState<PostInput> createState() => _PostInputState();
}

class _PostInputState extends ConsumerState<PostInput> {
  final _controller = TextEditingController();
  String? _imageUri;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final resident = ref.read(residentProvider).resident;
    if (resident == null) return;

    ref.read(postProvider.notifier).addPost(
          worldId: widget.worldId,
          residentId: resident.id,
          residentName: resident.name,
          residentAvatar: resident.avatarUrl,
          content: content,
          imageUri: _imageUri,
          tierValue: resident.tier.value,
        );

    _controller.clear();
    setState(() => _imageUri = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _submit,
                      color: theme.colorScheme.primary,
                    ),
                    ImagePickerWidget(
                      onImageSelected: (uri) => setState(() => _imageUri = uri),
                    ),
                  ],
                ),
              ],
            ),
            if (_imageUri != null) ...[
              const SizedBox(height: 8),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_imageUri!, height: 80, width: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _imageUri = null),
                      style: IconButton.styleFrom(backgroundColor: theme.colorScheme.error),
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
