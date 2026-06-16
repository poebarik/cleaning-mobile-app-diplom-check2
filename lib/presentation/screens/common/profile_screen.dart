// lib/presentation/screens/common/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/user/user.dart';
import '../../../data/models/review/review.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../routes/route_names.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final int _targetUserId;
  bool _isInitialized = false;


  @override
  void initState() {
    super.initState();
    final currentUserId = ref.read(authProvider).user?.id;
    _targetUserId = widget.userId ?? currentUserId ?? 0;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ✅ Выполняем только один раз после того, как дерево виджетов построено
    if (!_isInitialized) {
      _isInitialized = true;

      // Откладываем обновление провайдера до следующего кадра
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final currentUserId = ref.read(authProvider).user?.id;
          ref.read(isOwnProfileProvider.notifier).state = _targetUserId == currentUserId;
        }
      });
    }
  }

  Future<void> _sendMessage(User profile) async {
    try {
      final chatRepo = ChatRepository();
      final chat = await chatRepo.createChat(
        participantId: profile.id,
        participantName: profile.fullName,
      );
      if (mounted) {
        context.push('${RouteNames.chatDetail}/${chat.id}', extra: chat);
      }
    } catch (e) {
      CustomSnackbar.showError(context, 'Ошибка: $e');
    }
  }

  void _inviteCleaner(User profile) {
    context.push(
      '/create-order-wizard',
      extra: {
        'serviceId': 1,
        'address': '',
        'orderDate': DateTime.now().add(const Duration(days: 1)),
        'cleanerId': profile.id,
      },
    );
  }

  void _editProfile(User profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(user: profile),
      ),
    ).then((_) {
      // Обновляем кэш профиля после редактирования
      ref.invalidate(profileProvider(_targetUserId));
      ref.invalidate(profileReviewsProvider(_targetUserId));
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Выйти')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider(_targetUserId));
    final reviewsAsync = ref.watch(profileReviewsProvider(_targetUserId));
    final isOwnProfile = ref.watch(isOwnProfileProvider);

    // ✅ ОТЛАДКА
    print('=== ProfileScreen Debug ===');
    print('Target userId: $_targetUserId');
    print('Is own profile: $isOwnProfile');

    profileAsync.when(
      data: (profile) => print('Profile loaded: ${profile.fullName}, role: ${profile.role}'),
      loading: () => print('Profile loading...'),
      error: (err, stack) => print('Profile error: $err'),
    );

    reviewsAsync.when(
      data: (reviews) => print('Reviews loaded: ${reviews.length} отзывов'),
      loading: () => print('Reviews loading...'),
      error: (err, stack) => print('Reviews error: $err'),
    );
    print('========================');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(profileAsync.when(
          data: (user) => user.fullName,
          loading: () => 'Профиль',
          error: (_, __) => 'Профиль',
        )),
        elevation: 0,
        actions: [
          if (isOwnProfile)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  profileAsync.whenData((user) => _editProfile(user));
                }
                if (value == 'logout') _logout();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                const PopupMenuItem(value: 'logout', child: Text('Выйти')),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider(_targetUserId));
          ref.invalidate(profileReviewsProvider(_targetUserId));
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: profileAsync.when(
            data: (profile) => Column(
              children: [
                _buildHeader(profile),
                if (profile.isCleaner) _buildCleanerStats(profile),
                _buildActions(profile, isOwnProfile),
                _buildReviewsSection(reviewsAsync),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildError(error.toString()),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(User profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradient),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  image: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(profile.avatarUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                    ? CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Text(
                    profile.fullName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                )
                    : null,
              ),
              if (profile.isCleaner && profile.isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.check, size: 16, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(profile.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Text(_getRoleText(profile.role), style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          if (profile.description != null && profile.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(profile.description!, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildCleanerStats(User profile) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.star_rate_rounded, 'Рейтинг', profile.rating?.toStringAsFixed(1) ?? '0'),
          _buildStatItem(Icons.cleaning_services_rounded, 'Уборок', profile.completedOrders?.toString() ?? '0'),
          _buildStatItem(Icons.work_outline, 'Опыт', '${profile.experienceYears ?? 0} лет'),
          if (profile.totalEarnings != null)
            _buildStatItem(Icons.monetization_on, 'Заработано', '${profile.totalEarnings!.toInt()} ₸'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildActions(User profile, bool isOwnProfile) {
    if (isOwnProfile) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _sendMessage(profile),
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Сообщение'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: profile.isCleaner ? () => _inviteCleaner(profile) : null,
              icon: const Icon(Icons.send),
              label: Text(profile.isCleaner ? 'Пригласить' : 'Нанять'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // Замените метод _buildReviewsSection и _buildReviewItem на эти:

  Widget _buildReviewsSection(AsyncValue<List<Review>> reviewsAsync) {
    return reviewsAsync.when(
      data: (reviews) {
        print('📊 Получено отзывов: ${reviews.length}');

        // Добавляем детальный вывод каждого отзыва для отладки
        for (var review in reviews) {
          print('  - Отзыв от ${review.authorName}: ${review.rating}★, "${review.comment.length > 50 ? review.comment.substring(0, 50) + '...' : review.comment}"');
          print('    Фото: ${review.imageObjectNames?.length ?? 0} шт.');
        }

        if (reviews.isEmpty) {
          return Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Icon(Icons.reviews_outlined, size: 48, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text(
                  'Нет отзывов',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Будьте первым, кто оставит отзыв',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ],
            ),
          );
        }

        // Группируем отзывы по рейтингу для статистики
        final ratingCounts = {
          1: reviews.where((r) => r.rating == 1).length,
          2: reviews.where((r) => r.rating == 2).length,
          3: reviews.where((r) => r.rating == 3).length,
          4: reviews.where((r) => r.rating == 4).length,
          5: reviews.where((r) => r.rating == 5).length,
        };

        final averageRating = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с общей статистикой
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(Icons.star_rate_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${averageRating.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          Row(
                            children: [
                              ...List.generate(5, (i) => Icon(
                                i < averageRating.round() ? Icons.star : Icons.star_border,
                                size: 16,
                                color: AppColors.warning,
                              )),
                              const SizedBox(width: 8),
                              Text(
                                '${reviews.length} ${_getReviewsWord(reviews.length)}',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Распределение по рейтингам (опционально)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = ratingCounts[star] ?? 0;
                    final percentage = reviews.isEmpty ? 0 : (count / reviews.length * 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Row(
                              children: [
                                Text('$star', style: const TextStyle(fontSize: 12)),
                                const Icon(Icons.star, size: 12, color: AppColors.warning),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: AppColors.divider,
                                color: AppColors.warning,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 35,
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 24),

              // Список отзывов
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Отзывы',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviews.length > 5 ? 5 : reviews.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => _buildReviewItemImproved(reviews[index]),
              ),

              if (reviews.length > 5)
                Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to all reviews page
                      CustomSnackbar.showInfo(context, 'Скоро здесь будет полный список отзывов');
                    },
                    child: Text('Показать все (${reviews.length})'),
                  ),
                ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
      loading: () => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildReviewItemImproved(Review review) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Шапка отзыва
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: review.authorAvatarUrl != null
                    ? NetworkImage(review.authorAvatarUrl!)
                    : null,
                child: review.authorAvatarUrl == null
                    ? Text(
                  review.authorName.isNotEmpty ? review.authorName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          size: 14,
                          color: AppColors.warning,
                        )),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(fontSize: 11, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Тип отзыва (бейдж)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: review.reviewType == 'CLIENT_TO_CLEANER'
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  review.reviewType == 'CLIENT_TO_CLEANER' ? 'Клиент → Клинер' : 'Клинер → Клиент',
                  style: TextStyle(
                    fontSize: 9,
                    color: review.reviewType == 'CLIENT_TO_CLEANER' ? AppColors.primary : AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Текст отзыва
          if (review.comment.isNotEmpty)
            Text(
              review.comment,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),

          // Фото в отзыве
          if (review.imageObjectNames != null && review.imageObjectNames!.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageObjectNames!.length,
                itemBuilder: (context, index) {
                  final imageUrl = '${ApiConstants.baseUrl}/files/${review.imageObjectNames![index]}';
                  return GestureDetector(
                    onTap: () => _showImagePreview(context, imageUrl),
                    child: Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.background,
                            child: const Icon(Icons.broken_image, size: 40, color: AppColors.textHint),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

// Вспомогательный метод для показа увеличенного фото
  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 50, color: Colors.white),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getReviewsWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'отзыв';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) return 'отзыва';
    return 'отзывов';
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(error),
          const SizedBox(height: 16),
          CustomButton(
            onPressed: () {
              ref.invalidate(profileProvider(_targetUserId));
              ref.invalidate(profileReviewsProvider(_targetUserId));
            },
            text: 'Повторить',
          ),
        ],
      ),
    );
  }

  String _getRoleText(String role) {
    switch (role.toUpperCase()) {
      case 'CLIENT': return 'Клиент';
      case 'CLEANER': return 'Клинер';
      case 'MANAGER': return 'Менеджер';
      case 'ADMIN': return 'Администратор';
      default: return role;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}