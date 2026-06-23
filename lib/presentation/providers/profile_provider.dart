// lib/presentation/providers/profile_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/models/user/user.dart';
import '../../data/models/review/review.dart';
import 'auth_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository();
});

final profileProvider = FutureProvider.family<User, int>((ref, userId) async {
  final repository = ref.read(userRepositoryProvider);
  return await repository.getUserProfile(userId);
});

// ✅ Используем обновленный ReviewRepository
final profileReviewsProvider = FutureProvider.family<List<Review>, int>((ref, userId) async {
  print('📊 profileReviewsProvider вызван для userId: $userId');

  final repository = ref.read(reviewRepositoryProvider);

  try {
    final reviews = await repository.getUserReviews(userId);
    print('✅ Загружено ${reviews.length} отзывов для userId=$userId');
    return reviews;
  } catch (e) {
    print('❌ Ошибка загрузки отзывов: $e');
    return [];
  }
});

final isOwnProfileProvider = StateProvider<bool>((ref) => false);