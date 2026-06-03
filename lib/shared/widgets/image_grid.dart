import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final Function(int)? onImageTap;
  final Function(int)? onImageRemove;
  final double imageSize;

  const ImageGrid({
    super.key,
    required this.imageUrls,
    this.onImageTap,
    this.onImageRemove,
    this.imageSize = 100,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: imageUrls.asMap().entries.map((entry) {
        final index = entry.key;
        final url = entry.value;

        return Stack(
          children: [
            GestureDetector(
              onTap: onImageTap != null ? () => onImageTap!(index) : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  placeholder: (context, _) => Container(
                    width: imageSize,
                    height: imageSize,
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, _, __) => Container(
                    width: imageSize,
                    height: imageSize,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            ),
            if (onImageRemove != null)
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () => onImageRemove!(index),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}