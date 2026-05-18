import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../ui/icons/v_icons.dart';

class ImagePickerWidget extends StatelessWidget {
  final ValueChanged<String> onImageSelected;

  const ImagePickerWidget({super.key, required this.onImageSelected});

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (result != null) {
      onImageSelected(result.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.camera_alt_outlined),
      onPressed: () => _pickImage(context),
      tooltip: 'Add image',
    );
  }
}
