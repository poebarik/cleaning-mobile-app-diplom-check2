// lib/presentation/screens/common/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/order/order.dart';
import '../../../data/models/user/user.dart';
import '../../../data/models/review/review.dart';
import '../../../data/models/chat/chat.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/review_repository.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../../routes/route_names.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final int _targetUserId;
  bool _isInitialized = false;
  bool _isLoading = false;
  List<Order> _completedOrders = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ─── Цветовая палитра ─────────────────────────────────────────────
  static const Color _primaryPurple = Color(0xFF6C5CE7);
  static const Color _secondaryPurple = Color(0xFFA29BFE);
  static const Color _accentTeal = Color(0xFF00CEC9);
  static const Color _accentOrange = Color(0xFFFFA94D);
  static const Color _accentRed = Color(0xFFFF6B6B);
  static const Color _successGreen = Color(0xFF00B894);
  static const Color _darkText = Color(0xFF2D3436);
  static const Color _grayText = Color(0xFF636E72);
  static const Color _lightGray = Color(0xFFB2BEC3);
  static const Color _bgLight = Color(0xFFF8F9FA);
  static const Color _bgCard = Color(0xFFF0EFF8);

  @override
  void initState() {
    super.initState();
    final currentUserId = ref.read(authProvider).user?.id;
    _targetUserId = widget.userId ?? currentUserId ?? 0;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    // Загружаем данные
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompletedOrders();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _isInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final currentUserId = ref.read(authProvider).user?.id;
          ref.read(isOwnProfileProvider.notifier).state =
              _targetUserId == currentUserId;
        }
      });
    }
  }

  // ─── Загрузка заказов ─────────────────────────────────────────────

  Future<void> _loadCompletedOrders() async {
    try {
      final orderRepo = OrderRepository();
      final reviewRepo = ReviewRepository();
      final currentUser = ref.read(authProvider).user;

      if (!mounted) return;

      final profileAsync = ref.read(profileProvider(_targetUserId));
      final profile = profileAsync.value;

      if (profile == null) {
        print('⚠️ Профиль не загружен');
        return;
      }

      final isTargetCleaner = profile.isCleaner;

      print('🔍 Загрузка завершенных заказов:');
      print('  - Целевой пользователь: ${profile.fullName} (ID: ${profile.id})');
      print('  - Текущий пользователь: ${currentUser?.fullName} (ID: ${currentUser?.id})');

      List<Order> orders = [];

      if (isTargetCleaner) {
        final cleanerId = profile.cleanerId ?? profile.id;
        orders = await orderRepo.getCompletedCleanerOrders(cleanerId);
      } else {
        orders = await orderRepo.getCompletedClientOrders(_targetUserId);
      }

      if (!mounted) return;

      // ✅ Получаем все отзывы, которые уже оставил текущий пользователь
      final myReviews = await reviewRepo.getMyReviews();
      final reviewedOrderIds = myReviews.map((r) => r.orderId).toSet();

      print('📋 Уже оставлены отзывы для заказов: $reviewedOrderIds');

      // ✅ ФИЛЬТРУЕМ ЗАКАЗЫ
      final filteredOrders = orders.where((o) {
        final currentUserId = ref.read(authProvider).user?.id;

        // 1. Проверка: является ли текущий пользователь клиентом
        bool isCurrentUserClient = o.clientId == currentUserId || o.userId == currentUserId;

        // 2. Проверка: является ли текущий пользователь НАЗНАЧЕННЫМ клинером
        bool isCurrentUserCleaner = false;

        // Проверка через selectedCleanerName
        if (currentUser?.fullName != null && o.selectedCleanerName == currentUser?.fullName) {
          isCurrentUserCleaner = true;
        }

        // Проверка через cleanerId (если есть)
        if (!isCurrentUserCleaner && currentUser?.cleanerId != null) {
          isCurrentUserCleaner = o.cleanerId == currentUser?.cleanerId;
        }

        // ✅ Проверяем только ACCEPTED отклики!
        if (!isCurrentUserCleaner && o.responses != null) {
          isCurrentUserCleaner = o.responses!.any((r) {
            return (r.status == 'ACCEPTED') &&
                (r.cleanerId == currentUser?.cleanerId ||
                    r.cleanerName == currentUser?.fullName);
          });
        }

        // ✅ Пользователь должен быть участником заказа
        final isParticipant = isCurrentUserClient || isCurrentUserCleaner;

        if (!isParticipant) {
          print('  ⏭️ Заказ ${o.id} пропущен (пользователь не участник)');
          return false;
        }

        // ✅ Проверяем, есть ли уже отзыв от текущего пользователя
        final hasReview = reviewedOrderIds.contains(o.id);
        if (hasReview) {
          print('  ⏭️ Заказ ${o.id} пропущен (уже есть отзыв)');
          return false;
        }

        print('  ✅ Заказ ${o.id}: участник = true, отзыва нет');
        return true;
      }).toList();

      if (!mounted) return;

      setState(() {
        _completedOrders = filteredOrders;
      });

      print('✅ Найдено ${filteredOrders.length} заказов для отзыва');
      for (final order in filteredOrders) {
        print('  ✅ Заказ ${order.id}: ${order.clientName} → ${order.selectedCleanerName}');
      }

    } catch (e) {
      print('❌ Ошибка загрузки завершенных заказов: $e');
      if (!mounted) return;
      setState(() {
        _completedOrders = [];
      });
    }
  }

  bool _canLeaveReview() {
    final currentUserId = ref.read(authProvider).user?.id;
    if (_targetUserId == currentUserId) return false;
    if (_completedOrders.isEmpty) return false;
    return _completedOrders.any((order) => order.id != null);
  }

  // ─── Действия ─────────────────────────────────────────────────────

  Future<void> _sendMessage(User profile) async {
    try {
      final chatRepo = ChatRepository();
      setState(() {});

      print('🔍 Ищем чат с пользователем ${profile.id} (${profile.fullName})');

      final chats = await chatRepo.getChats();
      print('📋 Найдено чатов: ${chats.length}');

      Chat? existingChat;
      final currentUserId = ref.read(authProvider).user?.id;

      for (final chat in chats) {
        final isParticipant = chat.clientId == _targetUserId || chat.cleanerId == _targetUserId;
        final isCurrentUser = chat.clientId == currentUserId || chat.cleanerId == currentUserId;

        if (isParticipant && isCurrentUser) {
          existingChat = chat;
          print('✅ Найден существующий чат: ${chat.id}');
          break;
        }
      }

      if (existingChat != null) {
        if (mounted) {
          context.push('${RouteNames.chatDetail}/${existingChat.id}', extra: existingChat);
        }
      } else {
        print('⚠️ Чат не найден, создаем новый...');

        final newChat = await chatRepo.createChat(
          participantId: profile.id,
          participantName: profile.fullName,
        );

        print('✅ Создан новый чат: ${newChat.id}');

        if (mounted) {
          context.push('${RouteNames.chatDetail}/${newChat.id}', extra: newChat);
        }
      }
    } catch (e) {
      print('❌ Ошибка при открытии чата: $e');
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    }
  }

  void _inviteCleaner(User profile) {
    context.push(
      '/draft-order',
      extra: {
        'cleanerId': profile.id,
        'cleaningType': null,
        'templateName': null,
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
      ref.invalidate(profileProvider(_targetUserId));
      ref.invalidate(profileReviewsProvider(_targetUserId));
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Выход из аккаунта',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            color: _darkText,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'Вы уверены, что хотите выйти?',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: _grayText,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _lightGray),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Отмена',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: _grayText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _accentRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Выйти',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          ref.invalidate(profileProvider(_targetUserId));
          ref.invalidate(profileReviewsProvider(_targetUserId));
          context.go('/login');
        }
      } catch (e) {
        if (mounted) {
          CustomSnackbar.showError(context, 'Ошибка выхода: $e');
        }
      }
    }
  }

  // ✅ ИСПРАВЛЕННЫЙ МЕТОД - с принудительным обновлением
  void _navigateToCreateReview(User profile) {
    final currentUserId = ref.read(authProvider).user?.id;
    final isOwnProfile = _targetUserId == currentUserId;

    if (isOwnProfile) {
      CustomSnackbar.showError(context, 'Нельзя оставить отзыв о себе');
      return;
    }

    if (_completedOrders.isEmpty) {
      CustomSnackbar.showError(context, 'Нет заказов для отзыва');
      return;
    }

    final currentUser = ref.read(authProvider).user;
    final isCurrentUserClient = currentUser?.role == 'CLIENT';

    final order = _completedOrders.first;

    print('📝 Выбран заказ для отзыва: ${order.id}');
    print('  - Клиент: ${order.clientName}');
    print('  - Клинер: ${order.selectedCleanerName}');
    print('  - Статус: ${order.status}');
    print('  - orderId: ${order.id}');

    if (order.id == null) {
      print('❌ Ошибка: order.id = null');
      CustomSnackbar.showError(context, 'Ошибка: ID заказа не найден');
      return;
    }

    if (order.id! <= 0) {
      print('❌ Ошибка: order.id = ${order.id} (некорректный)');
      CustomSnackbar.showError(context, 'Ошибка: некорректный ID заказа');
      return;
    }

    int targetUserId;
    String targetUserName;
    String reviewType;

    if (isCurrentUserClient) {
      reviewType = 'CLIENT_TO_CLEANER';
      targetUserId = profile.cleanerId ?? profile.id;
      targetUserName = profile.fullName;
    } else {
      reviewType = 'CLEANER_TO_CLIENT';
      targetUserId = profile.id;
      targetUserName = profile.fullName;
    }

    print('📝 Создание отзыва:');
    print('  - orderId: ${order.id}');
    print('  - targetUserId: $targetUserId');
    print('  - targetUserName: $targetUserName');
    print('  - reviewType: $reviewType');

    // ✅ ИСПРАВЛЕНИЕ: Ждем результат и обновляем все данные
    context.push(
      '/create-review',
      extra: {
        'orderId': order.id,
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'reviewType': reviewType,
      },
    ).then((result) {
      // ✅ Принудительно инвалидируем все кеши
      print('🔄 Возврат с экрана создания отзыва, обновляем данные...');

      // 1. Инвалидируем кеш отзывов
      ref.invalidate(profileReviewsProvider(_targetUserId));

      // 2. Инвалидируем кеш профиля
      ref.invalidate(profileProvider(_targetUserId));

      // 3. Очищаем кеш репозитория отзывов
      ref.invalidate(reviewRepositoryProvider);

      // 4. Перезагружаем заказы с задержкой для синхронизации
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _loadCompletedOrders();
          // Дополнительно обновляем UI
          setState(() {});
        }
      });

      // 5. Показываем сообщение об успехе, если отзыв был создан
      if (result == true) {
        CustomSnackbar.showSuccess(context, 'Отзыв успешно создан!');
      }
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider(_targetUserId));
    final reviewsAsync = ref.watch(profileReviewsProvider(_targetUserId));
    final isOwnProfile = ref.watch(isOwnProfileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: profileAsync.when(
        data: (profile) => RefreshIndicator(
          color: _primaryPurple,
          onRefresh: () async {
            // ✅ Полное обновление при pull-to-refresh
            ref.invalidate(profileProvider(_targetUserId));
            ref.invalidate(profileReviewsProvider(_targetUserId));
            ref.invalidate(reviewRepositoryProvider);
            await _loadCompletedOrders();
            await Future.delayed(const Duration(milliseconds: 500));
            // Обновляем UI
            if (mounted) setState(() {});
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                title: Text(
                  profile.fullName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: _darkText,
                  ),
                ),
                actions: [
                  if (isOwnProfile)
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _bgLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.more_horiz_rounded,
                          color: _darkText,
                          size: 20,
                        ),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') _editProfile(profile);
                        if (value == 'logout') _logout();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 18, color: _primaryPurple),
                              SizedBox(width: 10),
                              Text('Редактировать', style: TextStyle(fontFamily: 'Poppins')),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, size: 18, color: _accentRed),
                              SizedBox(width: 10),
                              Text('Выйти', style: TextStyle(fontFamily: 'Poppins')),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildHeroSection(profile),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            if (profile.isCleaner) ...[
                              _buildStatsCard(profile),
                              const SizedBox(height: 16),
                              _buildVerificationCard(profile),
                              const SizedBox(height: 16),
                            ],
                            if (profile.description != null &&
                                profile.description!.isNotEmpty) ...[
                              _buildAboutCard(profile),
                              const SizedBox(height: 16),
                            ],
                            if (!isOwnProfile) ...[
                              _buildActionsCard(profile),
                              const SizedBox(height: 16),
                              _buildReviewActionCard(profile),
                              const SizedBox(height: 16),
                            ],
                            _buildReviewsSection(reviewsAsync),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: _primaryPurple),
        ),
        error: (error, stack) => _buildError(error.toString()),
      ),
    );
  }

  // ─── Hero Section ─────────────────────────────────────────────────

  Widget _buildHeroSection(User profile) {
    final hasAvatar = profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primaryPurple, _secondaryPurple],
        ),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: hasAvatar
                        ? CachedNetworkImage(
                      imageUrl: profile.avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: _primaryPurple,
                          strokeWidth: 2,
                        ),
                      ),
                      errorWidget: (context, url, error) =>
                          _buildAvatarPlaceholder(profile),
                    )
                        : _buildAvatarPlaceholder(profile),
                  ),
                ),
              ),
              if (profile.isCleaner && profile.isVerified)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_successGreen, Color(0xFF55EFC4)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getRoleText(profile.role),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                if (profile.isCleaner && profile.rating != null) ...[
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    width: 1,
                    height: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    profile.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (profile.isCleaner && profile.isVerified) ...[
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    width: 1,
                    height: 12,
                    color: Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 3),
                  const Text(
                    'Verified',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(User profile) {
    return Container(
      color: _bgCard,
      child: Center(
        child: Text(
          profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: _primaryPurple,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  // ─── Stats Card ───────────────────────────────────────────────────

  Widget _buildStatsCard(User profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryPurple, _secondaryPurple],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            icon: Icons.star_rounded,
            value: profile.rating?.toStringAsFixed(1) ?? '—',
            label: 'Рейтинг',
            iconColor: Colors.amber,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.cleaning_services_rounded,
            value: profile.completedOrders?.toString() ?? '0',
            label: 'Уборок',
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.work_outline_rounded,
            value: '${profile.experienceYears ?? 0}',
            label: 'Лет опыта',
          ),
          if (profile.totalEarnings != null) ...[
            _buildStatDivider(),
            _buildStatItem(
              icon: Icons.monetization_on_rounded,
              value: '${profile.totalEarnings!.toInt()} ₸',
              label: 'Заработано',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? iconColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: iconColor ?? Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.25),
    );
  }

  // ─── Verification Card ────────────────────────────────────────────

  Widget _buildVerificationCard(User profile) {
    if (!profile.isCleaner) return const SizedBox.shrink();

    final isVerified = profile.verificationStatus == 'VERIFIED';
    final isPending = profile.verificationStatus == 'PENDING';
    final isRejected = profile.verificationStatus == 'REJECTED';

    Color statusColor;
    String statusTitle;
    IconData statusIcon;
    List<Color> gradientColors;

    if (isVerified) {
      statusColor = _successGreen;
      statusTitle = 'Верифицированный клинер';
      statusIcon = Icons.verified_rounded;
      gradientColors = const [_successGreen, Color(0xFF55EFC4)];
    } else if (isPending) {
      statusColor = _accentOrange;
      statusTitle = 'Верификация на проверке';
      statusIcon = Icons.hourglass_top_rounded;
      gradientColors = const [_accentOrange, Color(0xFFFFD180)];
    } else if (isRejected) {
      statusColor = _accentRed;
      statusTitle = 'Верификация отклонена';
      statusIcon = Icons.error_rounded;
      gradientColors = const [_accentRed, Color(0xFFFF8E8E)];
    } else {
      statusColor = _lightGray;
      statusTitle = 'Верификация не пройдена';
      statusIcon = Icons.verified_outlined;
      gradientColors = const [_lightGray, Color(0xFFDFE6E9)];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(statusIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusTitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isVerified) ...[
            _buildVerificationItem('Паспорт подтвержден', profile.identityVerified),
            const SizedBox(height: 8),
            _buildVerificationItem(
                'Справка о несудимости', profile.criminalRecordVerified),
            const SizedBox(height: 8),
            _buildVerificationItem(
                'Медицинская справка', profile.medicalCertificateVerified),
          ] else if (isPending)
            _buildStatusMessage(
              icon: Icons.hourglass_top_rounded,
              text: 'Документы на проверке. Обычно это занимает до 24 часов.',
              color: _accentOrange,
            )
          else if (isRejected)
              _buildStatusMessage(
                icon: Icons.error_rounded,
                text: 'Верификация отклонена. Пожалуйста, загрузите документы заново.',
                color: _accentRed,
              )
            else
              _buildStatusMessage(
                icon: Icons.info_outline_rounded,
                text: 'Пройдите верификацию, чтобы повысить доверие клиентов.',
                color: _lightGray,
              ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String text, bool? verified) {
    final isVerified = verified == true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isVerified
            ? _successGreen.withOpacity(0.08)
            : _lightGray.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: isVerified ? _successGreen : _lightGray,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isVerified ? _darkText : _lightGray,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── About Card ───────────────────────────────────────────────────

  Widget _buildAboutCard(User profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_outline_rounded, color: _primaryPurple, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'О себе',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            profile.description!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _grayText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions Card ─────────────────────────────────────────────────

  Widget _buildActionsCard(User profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.chat_bubble_rounded,
              label: 'Сообщение',
              onTap: () => _sendMessage(profile),
              gradientColors: const [_accentTeal, Color(0xFF55EFC4)],
            ),
          ),
          if (profile.isCleaner) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.send_rounded,
                label: 'Пригласить',
                onTap: () => _inviteCleaner(profile),
                gradientColors: const [_primaryPurple, _secondaryPurple],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required List<Color> gradientColors,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradientColors),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Review Action Card ───────────────────────────────────────────

  Widget _buildReviewActionCard(User profile) {
    final currentUserId = ref.read(authProvider).user?.id;
    final isOwnProfile = _targetUserId == currentUserId;

    if (isOwnProfile) return const SizedBox.shrink();

    if (_completedOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _bgLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _lightGray.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline_rounded, color: _lightGray, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Нет завершенных заказов для отзыва',
                style: TextStyle(
                  fontSize: 13,
                  color: _grayText,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentUser = ref.read(authProvider).user;
    final isCurrentUserClient = currentUser?.role == 'CLIENT';

    String reviewTargetName;
    if (isCurrentUserClient) {
      reviewTargetName = profile.fullName;
    } else {
      reviewTargetName = profile.fullName;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToCreateReview(profile),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_accentOrange, Color(0xFFFFD180)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _accentOrange.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rate_review_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Оставить отзыв о $reviewTargetName',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_completedOrders.length} ${_getReviewsWord(_completedOrders.length)} доступно',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Reviews Section ──────────────────────────────────────────────

  Widget _buildReviewsSection(AsyncValue<List<Review>> reviewsAsync) {
    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEEF0F5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _bgLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.reviews_rounded,
                    size: 40,
                    color: _lightGray,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Пока нет отзывов',
                  style: TextStyle(
                    fontSize: 16,
                    color: _darkText,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Будьте первым, кто оставит отзыв',
                  style: TextStyle(
                    fontSize: 13,
                    color: _grayText,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          );
        }

        final ratingCounts = {
          1: reviews.where((r) => r.rating == 1).length,
          2: reviews.where((r) => r.rating == 2).length,
          3: reviews.where((r) => r.rating == 3).length,
          4: reviews.where((r) => r.rating == 4).length,
          5: reviews.where((r) => r.rating == 5).length,
        };

        final averageRating =
            reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEF0F5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_accentOrange, Color(0xFFFFD180)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _accentOrange.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Отзывы',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: _darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryPurple, _secondaryPurple],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryPurple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                                (i) => Icon(
                              i < averageRating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 12,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [5, 4, 3, 2, 1].map((star) {
                        final count = ratingCounts[star] ?? 0;
                        final percentage =
                        reviews.isEmpty ? 0 : (count / reviews.length * 100);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 24,
                                child: Row(
                                  children: [
                                    Text(
                                      '$star',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _darkText,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 10,
                                      color: Colors.amber,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: _bgLight,
                                    color: Colors.amber,
                                    minHeight: 5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 24,
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: _grayText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: const Color(0xFFEEF0F5), height: 1),
              const SizedBox(height: 16),
              Text(
                'Все отзывы (${reviews.length})',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 12),
              ...reviews.take(5).map((review) => _buildReviewCard(review)),
              if (reviews.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        context.push('/reviews/$_targetUserId/all');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        backgroundColor: _primaryPurple.withOpacity(0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Показать все (${reviews.length})',
                        style: const TextStyle(
                          color: _primaryPurple,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: _primaryPurple),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _bgLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: review.authorAvatarUrl != null
                      ? null
                      : const LinearGradient(
                    colors: [_primaryPurple, _secondaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  image: review.authorAvatarUrl != null
                      ? DecorationImage(
                    image: NetworkImage(review.authorAvatarUrl!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: review.authorAvatarUrl == null
                    ? Center(
                  child: Text(
                    review.authorName.isNotEmpty
                        ? review.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              fontFamily: 'Poppins',
                              color: _darkText,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: review.reviewType == 'CLIENT_TO_CLEANER'
                                ? _primaryPurple.withOpacity(0.12)
                                : _accentTeal.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            review.reviewType == 'CLIENT_TO_CLEANER'
                                ? 'Клиент'
                                : 'Клинер',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: review.reviewType == 'CLIENT_TO_CLEANER'
                                  ? _primaryPurple
                                  : _accentTeal,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                              (i) => Icon(
                            i < review.rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            size: 12,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(review.createdAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: _lightGray,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 12,
                color: _grayText,
                height: 1.4,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          if (review.imageObjectNames != null &&
              review.imageObjectNames!.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageObjectNames!.length,
                itemBuilder: (context, index) {
                  final imageUrl =
                      '${ApiConstants.baseUrl}/files/${review.imageObjectNames![index]}';
                  return GestureDetector(
                    onTap: () => _showImagePreview(context, imageUrl),
                    child: Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEF0F5)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: _bgLight,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primaryPurple,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: _bgLight,
                            child: const Icon(
                              Icons.broken_image_rounded,
                              size: 32,
                              color: _lightGray,
                            ),
                          ),
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error State ──────────────────────────────────────────────────

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _accentRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 48, color: _accentRed),
            ),
            const SizedBox(height: 20),
            const Text(
              'Ошибка загрузки',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: _darkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: _grayText,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(profileProvider(_targetUserId));
                ref.invalidate(profileReviewsProvider(_targetUserId));
                ref.invalidate(reviewRepositoryProvider);
                _loadCompletedOrders();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Повторить',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                backgroundColor: _primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────

  String _getRoleText(String role) {
    switch (role.toUpperCase()) {
      case 'CLIENT':
        return 'Клиент';
      case 'CLEANER':
        return 'Клинер';
      case 'MANAGER':
        return 'Менеджер';
      case 'ADMIN':
        return 'Администратор';
      default:
        return role;
    }
  }

  String _getReviewsWord(int count) {
    if (count % 10 == 1 && count % 100 != 11) return 'отзыв';
    if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) {
      return 'отзыва';
    }
    return 'отзывов';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}