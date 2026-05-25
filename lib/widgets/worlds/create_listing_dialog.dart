import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/world_capability_matrix.dart';
import '../../models/listing.dart';
import '../../services/marketplace_service.dart';
import '../../state/world_provider.dart';
import '../../services/media_service.dart';
import '../../state/resident_provider.dart';
import '../../theme/v_colors.dart';
import '../../theme/v_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/core/v_feedback.dart';

class CreateListingDialog extends ConsumerStatefulWidget {
  final String worldId;

  const CreateListingDialog({super.key, required this.worldId});

  @override
  ConsumerState<CreateListingDialog> createState() =>
      _CreateListingDialogState();
}

class _CreateListingDialogState extends ConsumerState<CreateListingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _priceNoteController = TextEditingController();
  final _coinPriceController = TextEditingController();
  ListingCategory _selectedCategory = ListingCategory.general;
  String? _imagePath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _priceNoteController.dispose();
    _coinPriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final resident = ref.read(residentProvider).resident;
    final world = ref.read(worldProvider).worlds[widget.worldId];
    if (world == null) {
      VFeedback.showError(context, 'World not found');
      return;
    }
    final block = WorldCapabilityMatrix.blockReasonCreateListing(
      resident,
      world,
      isJoined: resident?.joinedWorldIds.contains(widget.worldId) ?? false,
    );
    if (block != null) {
      VFeedback.showError(context, block);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_imagePath != null) {
        final resident = ref.read(residentProvider).resident;
        if (resident != null) {
          imageUrl = await MediaService.uploadPostImage(
            _imagePath!,
            resident.id,
          );
        }
      }

      int? coinPrice;
      final coinRaw = _coinPriceController.text.trim();
      if (coinRaw.isNotEmpty) {
        coinPrice = int.tryParse(coinRaw);
        if (coinPrice == null || coinPrice <= 0) {
          VFeedback.showError(context, 'Coin price must be a positive number');
          setState(() => _isSubmitting = false);
          return;
        }
      }

      await MarketplaceService.createListing(
        widget.worldId,
        _titleController.text.trim(),
        _descriptionController.text.trim(),
        _priceController.text.trim().isEmpty ? null : _priceController.text.trim(),
        _priceNoteController.text.trim().isEmpty ? null : _priceNoteController.text.trim(),
        _selectedCategory,
        imageUrl,
        coinPrice: coinPrice,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        VFeedback.showMessage(context, 'Listing created!');
      }
    } catch (e) {
      if (mounted) {
        VFeedback.showError(context, 'Failed to create listing: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(VSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? VColors.surfaceContainerDark : VColors.surface,
          borderRadius: BorderRadius.circular(VRadius.xl),
          border: Border.all(
            color: isDark ? VColors.glassBorderDark : VColors.glassBorder,
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Create Listing',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: VFontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: VSpacing.lg),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: VSpacing.md),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  maxLength: 500,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: VSpacing.md),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (optional)',
                    hintText: 'e.g. \$50, 100 coins, Free',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sell),
                  ),
                  validator: (v) => null,
                ),
                const SizedBox(height: VSpacing.md),
                TextFormField(
                  controller: _priceNoteController,
                  decoration: const InputDecoration(
                    labelText: 'Price note (optional)',
                    hintText: 'e.g. Negotiable, DM for price',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: VSpacing.md),
                TextFormField(
                  controller: _coinPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Coin price (optional)',
                    hintText: 'Enables in-app purchase with sovereign coins',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monetization_on_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: VSpacing.md),
                DropdownButtonFormField<ListingCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ListingCategory.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(
                        cat.name[0].toUpperCase() + cat.name.substring(1),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCategory = v);
                  },
                ),
                const SizedBox(height: VSpacing.md),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _imagePath != null
                        ? 'Image selected'
                        : 'Upload Image (optional)',
                  ),
                ),
                if (_imagePath != null) ...[
                  const SizedBox(height: VSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VRadius.md),
                    child: Image.file(
                      File(_imagePath!),
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: VSpacing.lg),
                FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Listing'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
