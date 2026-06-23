import 'package:flutter/material.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Фоновый контент с эффектом размытия
        child,

        // Полупрозрачный оверлей
        Container(
          color: Colors.black.withOpacity(0.3),
        ),

        // GIF загрузки
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/videos/loadingNew.gif',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text(
              'Загрузка...',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}