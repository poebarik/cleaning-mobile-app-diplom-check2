import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImagePickerWidget extends StatefulWidget {
  final Function(List<XFile>) onImagesSelected;
  final int maxImages;
  final bool multiple;

  const ImagePickerWidget({
    super.key,
    required this.onImagesSelected,
    this.maxImages = 5,
    this.multiple = true,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    final List<XFile> images = [];

    if (widget.multiple) {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        images.addAll(picked);
      }
    } else {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (picked != null) {
        images.add(picked);
      }
    }

    if (images.isNotEmpty) {
      widget.onImagesSelected(images);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickImages,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_photo_alternate, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text('Выбрать фото (макс. ${widget.maxImages})'),
          ],
        ),
      ),
    );
  }
}