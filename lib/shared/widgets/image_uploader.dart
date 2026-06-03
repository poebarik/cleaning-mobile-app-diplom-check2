import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../presentation/providers/file_provider.dart';

class ImageUploader extends ConsumerStatefulWidget {
  final Function(List<String>) onImagesUploaded;
  final String? folder;
  final int maxImages;

  const ImageUploader({
    super.key,
    required this.onImagesUploaded,
    this.folder,
    this.maxImages = 5,
  });

  @override
  ConsumerState<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends ConsumerState<ImageUploader> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  bool _isUploading = false;

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (picked != null) {
      final remainingSlots = widget.maxImages - _selectedImages.length;
      setState(() {
        _selectedImages.addAll(picked.take(remainingSlots));
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    final notifier = ref.read(fileUploadProvider.notifier);
    final files = await notifier.uploadImages(_selectedImages, folder: widget.folder);

    if (files.isNotEmpty) {
      final objectNames = files.map((f) => f.objectName).toList();
      widget.onImagesUploaded(objectNames);

      setState(() {
        _selectedImages.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Фото успешно загружены')),
        );
      }
    }

    setState(() {
      _isUploading = false;
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(fileUploadProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (_selectedImages.isNotEmpty)
              ..._selectedImages.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      // ✅ Для Web используем Image.network или Image.memory
                      child: _buildImagePreview(entry.value),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => _removeImage(entry.key),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            if (_selectedImages.length < widget.maxImages)
              InkWell(
                onTap: _pickImages,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_photo_alternate, size: 40),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isNotEmpty)
          ElevatedButton(
            onPressed: _isUploading ? null : _uploadImages,
            child: _isUploading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Загрузить фото'),
          ),
        if (uploadState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              uploadState.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // ✅ Метод для отображения превью изображения с поддержкой Web
  Widget _buildImagePreview(XFile image) {
    final width = 80.0;
    final height = 80.0;

    // ✅ Для Web используем Image.network (через URL.createObjectURL)
    if (kIsWeb) {
      return Image.network(
        image.path, // На Web путь уже является URL
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image, size: 40),
          );
        },
      );
    }

    // ✅ Для мобильных платформ используем Image.file
    return Image.file(
      File(image.path),
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, size: 40),
        );
      },
    );
  }
}