// lib/presentation/screens/reviews/create_review_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../data/repositories/file_repository.dart';
import '../../../data/models/review/create_review_request.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../shared/widgets/image_uploader.dart';
import '../../../core/constants/api_constants.dart';

class CreateReviewScreen extends ConsumerStatefulWidget {
  final int orderId;
  final int targetUserId;
  final String targetUserName;
  final String reviewType; // "CLIENT_TO_CLEANER" или "CLEANER_TO_CLIENT"

  const CreateReviewScreen({
    super.key,
    required this.orderId,
    required this.targetUserId,
    required this.targetUserName,
    required this.reviewType,
  });

  @override
  ConsumerState<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends ConsumerState<CreateReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 0;
  List<String> _uploadedImages = [];
  bool _isLoading = false;
  bool _isUploading = false;
  List<String> _imageObjectNames = [];
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _ratingOptions = [
    {'value': 1, 'label': 'Ужасно', 'icon': Icons.sentiment_very_dissatisfied},
    {'value': 2, 'label': 'Плохо', 'icon': Icons.sentiment_dissatisfied},
    {'value': 3, 'label': 'Нормально', 'icon': Icons.sentiment_neutral},
    {'value': 4, 'label': 'Хорошо', 'icon': Icons.sentiment_satisfied},
    {'value': 5, 'label': 'Отлично', 'icon': Icons.sentiment_very_satisfied},
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }


  // lib/presentation/screens/reviews/create_review_screen.dart

  Future<void> _submitReview() async {
    if (_rating == 0) {
      CustomSnackbar.showError(context, 'Пожалуйста, поставьте оценку');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final reviewRepo = ReviewRepository();
      final request = CreateReviewRequest(
        orderId: widget.orderId,
        targetUserId: widget.targetUserId,
        rating: _rating,
        comment: _commentController.text.trim(),
        reviewType: widget.reviewType,
        imageObjectNames: _imageObjectNames,
      );

      final review = await reviewRepo.createReview(request);
      print('✅ Отзыв создан: ${review.id}');

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Отзыв успешно отправлен!');
        // ✅ Возвращаем true, чтобы обновить список на предыдущем экране
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetRole = widget.reviewType == 'CLIENT_TO_CLEANER' ? 'клинера' : 'клиента';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Оставить отзыв', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информация о ком отзыв
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradient),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Отзыв о $targetRole',
                            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.targetUserName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Рейтинг
              const Text(
                'Оценка',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Center(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _ratingOptions.map((option) {
                    final value = option['value'] as int;
                    final isSelected = _rating == value;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.divider,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8)]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              option['icon'],
                              size: 20,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              option['label'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Звезды
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () => setState(() => _rating = index + 1),
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                        size: 32,
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // Комментарий
              const Text(
                'Комментарий',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: _commentController,
                label: 'Расскажите о впечатлениях',
                hint: 'Что понравилось? Что можно улучшить?',
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, напишите комментарий';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Фото
              const Text(
                'Фотографии',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Добавьте фото результата (необязательно)',
                style: TextStyle(fontSize: 12, color: AppColors.textHint),
              ),
              const SizedBox(height: 12),
              ImageUploader(
                onImagesUploaded: (objectNames) {
                  setState(() {
                    _uploadedImages = objectNames;
                  });
                },
                folder: 'reviews',
                maxImages: 5,
              ),

              const SizedBox(height: 32),

              CustomButton(
                onPressed: _submitReview,
                text: 'Отправить отзыв',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}