// lib/presentation/screens/client/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/category_bottom_sheet.dart';
import '../../providers/order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/service_provider.dart';
import '../../providers/notification_provider.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../data/models/service/popular_service.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Все';
  late AnimationController _headerAnimController;
  late Animation<double> _headerFadeAnim;

  // ─── Scroll controller для sticky search ──────────────────────────
  final ScrollController _scrollController = ScrollController();
  bool _isSearchSticky = false;

  // ─── Цвета категорий ───────────────────────────────────────────────
  final Map<String, List<Color>> _categoryGradients = {
    'HOME': [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
    'OFFICE': [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
    'FURNITURE': [const Color(0xFFFFA94D), const Color(0xFFFFCC80)],
    'SPECIAL': [const Color(0xFF00CEC9), const Color(0xFF55EFC4)],
    'CAR': [const Color(0xFF0984E3), const Color(0xFF74B9FF)],
    'REPAIR': [const Color(0xFF6C5CE7), const Color(0xFFFF7675)],
  };

  final Map<String, String> _categoryIcons = {
    'Все': '🏠',
    'HOME': '🧹',
    'OFFICE': '🏢',
    'FURNITURE': '🛋️',
    'SPECIAL': '⭐',
    'CAR': '🚗',
    'REPAIR': '🔧',
  };

  // ─── Информационные блоки ──────────────────────────────────────────
  final List<_InfoBlockData> _infoBlocks = [
    _InfoBlockData(
      id: 0,
      title: 'Сколько стоит услуга',
      imagePath: 'assets/images/service.jpg',
      answer:
      'Вы можете сами указать, сколько готовы заплатить. Или подождать предложений специалистов. Цена зависит от сложности, объема работ и региона. Средняя цена в вашем городе — от 2000 до 15000 ₸.',
      color: const Color(0xFF6C5CE7),
    ),
    _InfoBlockData(
      id: 1,
      title: 'Настоящие отзывы',
      imagePath: 'assets/images/reviews.jpg',
      answer:
      'Все отзывы оставляют реальные клиенты после выполнения заказа. Мы проверяем каждую оценку и не допускаем накрутку. Вы можете видеть рейтинг каждого специалиста и читать подробные комментарии.',
      color: const Color(0xFF00CEC9),
    ),
    _InfoBlockData(
      id: 2,
      title: 'Это бесплатно',
      imagePath: 'assets/images/present.jpg',
      answer:
      'Создание заказа и размещение объявления — абсолютно бесплатно! Вы платите только за саму услугу специалисту. Никаких скрытых комиссий и платежей.',
      color: const Color(0xFFFFA94D),
    ),
  ];

  // ─── Промо-баннеры ─────────────────────────────────────────────────
  final List<_PromoBanner> _promoBanners = [
    _PromoBanner(
      title: 'Генеральная\nуборка',
      subtitle: 'Профессионалы у вас дома',
      imagePath: 'assets/images/generalCleaning.png',
      colors: [Color(0xFF6C5CE7), Color(0xFF8B7FF0)],
    ),
    _PromoBanner(
      title: 'Химчистка\nмебели',
      subtitle: 'Как новое за 1 день',
      imagePath: 'assets/images/furnitureCleaning.png',
      colors: [Color(0xFF00CEC9), Color(0xFF55EFC4)],
    ),
    _PromoBanner(
      title: 'Мойка\nавтомобиля',
      subtitle: 'Блеск без усилий',
      imagePath: 'assets/images/autoCleaning.png',
      colors: [Color(0xFF0984E3), Color(0xFF74B9FF)],
    ),
  ];

  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;

  @override
  void initState() {
    super.initState();
    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerAnimController.forward();

    // ✅ Слушаем скролл для sticky search
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(orderProvider.notifier).loadClientOrders();
      ref.read(notificationProvider.notifier).loadNotifications();
      ref.read(categoriesProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnimController.dispose();
    _bannerController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isSticky = _scrollController.offset > 180;
    if (isSticky != _isSearchSticky) {
      setState(() {
        _isSearchSticky = isSticky;
      });
    }
  }

  // ─── Навигация ──────────────────────────────────────────────────────

  void _openDraftOrder({String? cleaningType, String? templateName}) {
    context.pushNamed(
      'draftOrder',
      extra: {'cleaningType': cleaningType, 'templateName': templateName},
    );
  }

  void _openProfile() => context.push('/my-profile');
  void _openNotifications() => context.push('/notifications');
  void _openChats() => context.push('/chat-list');

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'HOME':
        return 'Дом';
      case 'OFFICE':
        return 'Офис';
      case 'FURNITURE':
        return 'Мебель';
      case 'SPECIAL':
        return 'Спец. услуги';
      case 'CAR':
        return 'Авто';
      case 'REPAIR':
        return 'Ремонт';
      default:
        return category;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final authState = ref.watch(authProvider);
    final notificationState = ref.watch(notificationProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;
    final firstName = user?.fullName.split(' ').first ?? 'Гость';

    final unreadCount = notificationState is NotificationStateLoaded
        ? notificationState.notifications.where((n) => !n.isRead).length
        : 0;

    final categoriesAsync = ref.watch(categoriesProvider);

    final servicesAsync = _selectedCategory == 'Все'
        ? ref.watch(popularServicesProvider)
        : ref.watch(servicesByCategoryProvider(_selectedCategory));

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: Stack(
        children: [
          // ✅ Основной контент с отступом для sticky search
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Gradient Hero Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeroHeader(user, firstName, unreadCount),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Отступ для поиска (теперь он вынесен отдельно)
                    const SizedBox(height: 50), // Место для sticky search

                    // ── Промо-баннеры ──────────────────────────────────
                    _buildPromoBanners(),
                    const SizedBox(height: 24),

                    // ── Категории ──────────────────────────────────────
                    _buildCategoryCards(),
                    const SizedBox(height: 20),

                    // ── Фильтр категорий ───────────────────────────────
                    _buildCategoryFilter(categoriesAsync),
                    const SizedBox(height: 16),

                    // ── Услуги ─────────────────────────────────────────
                    _buildServicesSection(servicesAsync),

                    // ── Информационные блоки ───────────────────────────
                    _buildInfoGrid(),

                    // ── Последние заказы ───────────────────────────────
                    _buildRecentOrders(orderState),

                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ],
          ),

          // ✅ Sticky Search Bar (поверх всего)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildStickySearchBar(),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ─── Sticky Search Bar ──────────────────────────────────────────────

  // ─── Sticky Search Bar ──────────────────────────────────────────────

  Widget _buildStickySearchBar() {
    final authState = ref.watch(authProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;
    final firstName = user?.fullName.split(' ').first ?? 'Гость';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: _isSearchSticky ? 52 : 0,
          curve: Curves.easeInOut,
          child: _isSearchSticky
              ? Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C5CE7).withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(
                  CupertinoIcons.search,
                  size: 18,
                  color: Color(0xFF6C5CE7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push('/search'),
                    child: Text(
                      'Поиск услуг или специалистов',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

// ─── Поиск в хедере ─────────────────────────────────────────────────



  // ─── Hero Header ────────────────────────────────────────────────────

  Widget _buildHeroHeader(UserEntity? user, String firstName, int unreadCount) {
    return FadeTransition(
      opacity: _headerFadeAnim,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6C5CE7), Color(0xFF8B7FF0), Color(0xFFA29BFE)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Аватар
                    GestureDetector(
                      onTap: _openProfile,
                      child: _buildAvatar(user, firstName),
                    ),
                    const SizedBox(width: 12),
                    // Приветствие
                    Expanded(
                      child: GestureDetector(
                        onTap: _openProfile,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Здравствуй!',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              firstName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Уведомления
                    _buildIconButton(
                      icon: Icons.notifications_outlined,
                      onTap: _openNotifications,
                      badgeCount: unreadCount,
                    ),
                    const SizedBox(width: 8),
                    _buildIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: _openChats,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Subtitle
                Text(
                  'Чем можем помочь сегодня?',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // ✅ Поиск в хедере (не sticky)
                const SizedBox(height: 16),
                _buildHeaderSearchBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Поиск в хедере ─────────────────────────────────────────────────

  // lib/presentation/screens/client/home_screen.dart

// ─── Поиск в хедере ─────────────────────────────────────────────────

  Widget _buildHeaderSearchBar() {
    return GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
          // ✅ Убираем backdropFilter - используем полупрозрачный фон
          // ✅ Убираем FilterQuality - он не нужен для BoxDecoration
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(
              CupertinoIcons.search,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              'Поиск услуг или специалистов',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.all(6),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
          if (badgeCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Аватар ─────────────────────────────────────────────────────────

  Widget _buildAvatar(UserEntity? user, String firstName) {
    final hasAvatar = user?.avatar != null && user!.avatar!.isNotEmpty;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: hasAvatar
            ? CachedNetworkImage(
          imageUrl: user!.avatar!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.white.withOpacity(0.3),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _avatarFallback(firstName),
        )
            : _avatarFallback(firstName),
      ),
    );
  }

  Widget _avatarFallback(String firstName) {
    return Container(
      color: Colors.white.withOpacity(0.25),
      child: Center(
        child: Text(
          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'G',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ─── Промо-баннеры ──────────────────────────────────────────────────


// ─── Build промо-баннеров ──────────────────────────────────────────

  Widget _buildPromoBanners() {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: Column(
        children: [
          SizedBox(
            height: 156,
            child: PageView.builder(
              controller: _bannerController,
              onPageChanged: (i) => setState(() => _currentBannerPage = i),
              itemCount: _promoBanners.length,
              itemBuilder: (context, index) {
                final banner = _promoBanners[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 16 : 8,
                    right: index == _promoBanners.length - 1 ? 16 : 8,
                  ),
                  child: GestureDetector(
                    onTap: () => _openDraftOrder(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: banner.colors,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: banner.colors.first.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Декор
                          Positioned(
                            right: -10,
                            top: -20,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 30,
                            bottom: -30,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.06),
                              ),
                            ),
                          ),
                          // ✅ Изображение вместо эмодзи
                          Positioned(
                            right: 10,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  banner.imagePath,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          // Текст
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  banner.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.85),
                                    fontFamily: 'Poppins',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                  child: const Text(
                                    'Заказать →',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _promoBanners.length,
                  (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentBannerPage ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentBannerPage
                      ? const Color(0xFF6C5CE7)
                      : const Color(0xFF6C5CE7).withOpacity(0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ─── Вспомогательный класс ─────────────────────────────────────────


  // ─── Категории ──────────────────────────────────────────────────────

  Widget _buildCategoryCards() {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();

        return FutureBuilder<List<PopularService>>(
          future: _loadServicesForCategories(categories),
          builder: (context, snapshot) {
            final allServices = snapshot.data ?? [];
            final Map<String, List<PopularService>> servicesByCategory = {};
            for (final s in allServices) {
              final cat = s.category ?? 'OTHER';
              servicesByCategory.putIfAbsent(cat, () => []).add(s);
            }

            final cards = categories.map((cat) {
              return _CategoryCard(
                id: cat,
                icon: _categoryIcons[cat] ?? '🏠',
                label: _getCategoryLabel(cat),
                gradientColors: _categoryGradients[cat] ??
                    [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)],
                services: servicesByCategory[cat] ?? [],
              );
            }).toList();

            final displayCards = cards.take(5).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Сервисы',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D3436),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/search'),
                        child: const Text(
                          'Все →',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C5CE7),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayCards.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == displayCards.length) {
                        return _buildMoreCard();
                      }
                      return _buildCategoryChip(displayCards[i]);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6C5CE7),
            ),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryChip(_CategoryCard card) {
    return GestureDetector(
      onTap: () {
        if (card.services.length == 1) {
          final service = card.services.first;
          context.push(
            '/draft-order',
            extra: {
              'cleaningType': service.defaultCleaningType ?? 'CUSTOM',
              'serviceName': service.name,
              'serviceId': service.id,
              'servicePrice': service.price,
              'serviceDescription': service.description,
            },
          );
        } else {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CategoryBottomSheet(
              category: card.id,
              categoryLabel: card.label,
              services: card.services,
            ),
          );
        }
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: card.gradientColors,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: card.gradientColors.first.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  card.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              card.label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreCard() {
    return GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        width: 80,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 26,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Ещё',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<PopularService>> _loadServicesForCategories(
      List<String> categories) async {
    final repository = ref.read(serviceRepositoryProvider);
    final allServices = <PopularService>[];
    for (final category in categories) {
      try {
        final services = await repository.getServicesByCategory(category);
        allServices.addAll(services);
      } catch (e) {
        print('❌ Ошибка загрузки услуг для категории $category: $e');
      }
    }
    return allServices;
  }

  // ─── Фильтр категорий ───────────────────────────────────────────────

  Widget _buildCategoryFilter(AsyncValue<List<String>> categoriesAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Популярные услуги',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3436),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          categoriesAsync.when(
            data: (categories) {
              final all = ['Все', ...categories];
              return SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: all.length,
                  itemBuilder: (ctx, i) {
                    final cat = all[i];
                    final isSelected = cat == _selectedCategory;
                    final label = cat == 'Все' ? 'Все' : _getCategoryLabel(cat);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                            colors: [
                              Color(0xFF6C5CE7),
                              Color(0xFFA29BFE),
                            ],
                          )
                              : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7)
                                  .withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                              : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ─── Секция услуг ────────────────────────────────────────────────────

  Widget _buildServicesSection(AsyncValue<List<PopularService>> servicesAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: servicesAsync.when(
        data: (services) => services.isEmpty
            ? _buildServicesEmpty()
            : Column(
          children: services.map((s) => _buildServiceCard(s)).toList(),
        ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(
              color: Color(0xFF6C5CE7),
              strokeWidth: 2,
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildServicesEmpty() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF0F5)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6C5CE7).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Text('🧹', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Нет услуг в этой категории',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF636E72),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// ─── Карточка услуги с локальным изображением ─────────────────────────

  Widget _buildServiceCard(PopularService service) {
    final gradients = _getServiceGradient(service);
    final hasImage = service.imageUrl != null && service.imageUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradients.first.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Фоновое изображение из assets или градиент
            if (hasImage)
              Image.asset(
                'assets/images/${service.imageUrl}',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 220,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradients,
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradients,
                  ),
                ),
              ),

            // Градиентный оверлей для читаемости текста
            Container(
              height: 220,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: hasImage
                      ? [
                    Colors.black.withOpacity(0.55),
                    Colors.black.withOpacity(0.25),
                  ]
                      : [
                    gradients.first.withOpacity(0.15),
                    gradients.last.withOpacity(0.05),
                  ],
                ),
              ),
            ),

            // Декоративные круги на фоне
            if (hasImage) ...[
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -30,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
            ],

            // Контент
            SizedBox(
              height: 220,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Верхняя часть: иконка + бейдж
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [

                      ],
                    ),
                    const SizedBox(height: 16),

                    // Название услуги
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              height: 1.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          if (service.description != null &&
                              service.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 240,
                              child: Text(
                                service.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.9),
                                  fontFamily: 'Poppins',
                                  height: 1.4,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Нижняя часть: цена и кнопка
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (service.price != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'от',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.8),
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${service.price!.toInt()} ₸',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          const Spacer(),
                        GestureDetector(
                          onTap: () => _openDraftOrder(
                            cleaningType: service.defaultCleaningType,
                            templateName: service.name,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Заказать',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: gradients.first,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: gradients.first,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getServiceGradient(PopularService service) {
    if (service.name.contains('Генеральная') || service.category == 'HOME') {
      return [const Color(0xFF6C5CE7), const Color(0xFF8B7FF0)];
    } else if (service.category == 'FURNITURE' ||
        service.name.contains('Химчистка')) {
      return [const Color(0xFFFFA94D), const Color(0xFFFFCC80)];
    } else if (service.category == 'SPECIAL') {
      return [const Color(0xFF00CEC9), const Color(0xFF55EFC4)];
    } else if (service.category == 'CAR') {
      return [const Color(0xFF0984E3), const Color(0xFF74B9FF)];
    } else if (service.category == 'OFFICE') {
      return [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)];
    }
    return [const Color(0xFF6C5CE7), const Color(0xFFA29BFE)];
  }
  // ─── Информационные блоки ────────────────────────────────────────────

  Widget _buildInfoGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Почему выбирают нас',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3436),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),

          // Первый ряд: 2 карточки
          Row(
            children: [
              Expanded(
                child: _buildGridCard(
                  title: 'Как работает\nсервис?',
                  imagePath: 'assets/images/service.jpg',
                  color: const Color(0xFFF8F9FA),
                  textColor: const Color(0xFF2D3436),
                  onTap: () => _showInfoBottomSheet(3),
                  height: 140,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGridCard(
                  title: 'Услуги в вашем\nгороде',
                  imagePath: 'assets/images/country.jpg',
                  color: const Color(0xFFF8F9FA),
                  textColor: const Color(0xFF2D3436),
                  onTap: () => _showInfoBottomSheet(4),
                  height: 140,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Второй ряд: 1 полная карточка с описанием
          _buildWideInfoCard(
            title: 'Сколько стоит услуга',
            description: 'Вы можете сами указать, сколько готовы заплатить. Или подождать предложений специалистов',
            imagePath: 'assets/images/money.jpg',
            color: const Color(0xFFF8F9FA),
            onTap: () => _showInfoBottomSheet(0),
          ),

          const SizedBox(height: 12),

          // Третий ряд: 2 карточки
          Row(
            children: [
              Expanded(
                child: _buildGridCard(
                  title: 'Настоящие\nотзывы',
                  imagePath: 'assets/images/reviews.jpg',
                  color: const Color(0xFFF8F9FA),
                  textColor: const Color(0xFF2D3436),
                  onTap: () => _showInfoBottomSheet(1),
                  height: 140,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGridCard(
                  title: 'Это\nбесплатно',
                  imagePath: 'assets/images/present.jpg',
                  color: const Color(0xFFF8F9FA),
                  textColor: const Color(0xFF2D3436),
                  onTap: () => _showInfoBottomSheet(2),
                  height: 140,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInfoBottomSheet(int id) {
    final Map<int, Map<String, dynamic>> infoDetails = {
      0: {
        'title': 'Нужно ли за что-то платить?',
        'body':
        'Вы платите напрямую специалисту — только за работу. Услуги сервиса для клиентов бесплатные.\n\nДля специалистов сервис платный. Они могут выбрать, как платить: сразу за отклик, или позже — когда завершат работу.',
        'icons': [Icons.receipt_long, Icons.payment, Icons.star_rounded],
        'color': const Color(0xFF6C5CE7),
        'imagePath': 'assets/images/present.jpg',
      },
      1: {
        'title': 'Отзывы настоящие?',
        'body':
        'У нас можно оставить отзыв только о тех, с кем вы работали или обсуждали условия задачи.\n\nА если кто-то попросит друга найти специалиста только ради отзыва, наши алгоритмы быстро это заметят и удалят оценку.',
        'icons': [Icons.rate_review, Icons.verified_user, Icons.pets],
        'color': const Color(0xFF6C5CE7),
        'imagePath': 'assets/images/reviews.jpg',
      },
      2: {
        'title': 'Сколько будет стоить работа специалиста?',
        'body':
        'При поиске специалиста вы можете сразу указать, сколько готовы заплатить. Для некоторых услуг мы подскажем среднюю рыночную цену.\n\nИли можно не указывать цену и просто дождаться предложений специалистов.',
        'icons': [Icons.savings, Icons.monetization_on, Icons.diamond],
        'color': const Color(0xFF6C5CE7),
        'imagePath': 'assets/images/money.jpg',
      },
      3: {
        'title': 'Как работает сервис?',
        'body':
        'Вы описываете детали задачи, а мы рассылаем её самым подходящим специалистам.\n\nТе, кто готов выполнить работу, присылают предложения с ценой. Вы сможете сравнить отзывы, пообщаться и выбрать того, кто понравится больше.',
        'icons': [Icons.handshake, Icons.groups, Icons.chat],
        'color': const Color(0xFF6C5CE7),
        'imagePath': 'assets/images/service.jpg',
      },
      4: {
        'title': 'Какие задачи решают профи?',
        'body':
        'У нас больше 900 видов услуг — от ремонта и косметологии до виртуальных экскурсий и обучения фламенко. Полный список услуг можно посмотреть в поиске.',
        'icons': [Icons.build, Icons.music_note, Icons.public],
        'color': const Color(0xFF6C5CE7),
        'imagePath': 'assets/images/country.jpg',
      },
    };

    final details = infoDetails[id] ?? infoDetails[0]!;
    final title = details['title'] as String;
    final body = details['body'] as String;
    final sheetColor = details['color'] as Color;
    final imagePath = details['imagePath'] as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: sheetColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: Image.asset(
                      imagePath,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: sheetColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '📸',
                              style: TextStyle(fontSize: 44),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3436),
                  fontFamily: 'Poppins',
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                body,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: sheetColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Понятно',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  Widget _buildGridCard({
    required String title,
    required String imagePath,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
    required double height,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Текст сверху
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.3,
              ),
            ),
            const Spacer(),
            // Картинка снизу по центру
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 35,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideInfoCard({
    required String title,
    required String description,
    required String imagePath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF636E72),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 35,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ─── Последние заказы ────────────────────────────────────────────────

  Widget _buildRecentOrders(dynamic orderState) {
    if (orderState.orders == null || orderState.orders!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Последние заказы',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3436),
                  fontFamily: 'Poppins',
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Все →',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6C5CE7),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...orderState.orders!.take(3).map<Widget>((order) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () =>
                      context.push('${RouteNames.orderDetails}/${order.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.cleaning_services_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.serviceName ?? 'Заказ #${order.id}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D3436),
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.address ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                  fontFamily: 'Poppins',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        StatusChip(status: order.status ?? 'PENDING'),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ─── FAB ─────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => _openDraftOrder(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Рассказать о задаче',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Вспомогательные классы ─────────────────────────────────────────────────

class _CategoryCard {
  final String id;
  final String icon;
  final String label;
  final List<Color> gradientColors;
  final List<PopularService> services;

  const _CategoryCard({
    required this.id,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.services,
  });
}


class _InfoBlockData {
  final int id;
  final String title;
  final String imagePath; // ✅ Путь к изображению вместо emoji
  final String answer;
  final Color color;

  const _InfoBlockData({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.answer,
    required this.color,
  });
}

class _PromoBanner {
  final String title;
  final String subtitle;
  final String imagePath;
  final List<Color> colors;

  const _PromoBanner({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.colors,
  });
}