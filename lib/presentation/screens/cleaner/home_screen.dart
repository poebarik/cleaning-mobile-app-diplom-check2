// lib/presentation/screens/cleaner/home_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/route_names.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/models/order/order.dart';
import '../../../presentation/providers/auth_provider.dart';

class CleanerHomeScreen extends ConsumerStatefulWidget {
  const CleanerHomeScreen({super.key});

  @override
  ConsumerState<CleanerHomeScreen> createState() => _CleanerHomeScreenState();
}

class _CleanerHomeScreenState extends ConsumerState<CleanerHomeScreen> {
  List<Order> _openOrders = [];
  bool _isLoading = true;
  String? _error;
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadOpenOrders();
  }

  Future<void> _loadOpenOrders() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final repository = OrderRepository();
      final orders = await repository.getOpenMarketplaceOrders();
      setState(() { _openOrders = orders; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;
    final firstName = user?.fullName.split(' ').first ?? 'Клинер';

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(firstName),
            _buildStats(),
            _buildSectionTitle(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String firstName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF8B7FF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C5CE7),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.23),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'K',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добро пожаловать! 👋',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              _headerButton(CupertinoIcons.bell, () => context.push(RouteNames.notifications)),
              const SizedBox(width: 10),
              _headerButton(CupertinoIcons.chat_bubble_2, () => context.push(RouteNames.chatList)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        children: [
          _statCard('${_openOrders.length}', 'Заказов', CupertinoIcons.briefcase, const Color(0xFF6C5CE7)),
          const SizedBox(width: 12),
          _statCard('4.9', 'Рейтинг', CupertinoIcons.star, const Color(0xFFFFB800)),
          const SizedBox(width: 12),
          _statCard('12', 'Выполнено', CupertinoIcons.checkmark_circle, const Color(0xFF00CEC9)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF636E72),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Доступные заказы',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Color(0xFF2D3436),
            ),
          ),
          GestureDetector(
            onTap: _loadOpenOrders,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C5CE7).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.refresh, size: 14, color: const Color(0xFF6C5CE7)),
                  const SizedBox(width: 4),
                  const Text(
                    'Обновить',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6C5CE7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFFEB3B5A).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.exclamationmark_triangle, size: 40, color: Color(0xFFEB3B5A)),
            ),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF636E72))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadOpenOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Повторить', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_openOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: const Color(0xFF6C5CE7).withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.square_list, size: 48, color: Color(0xFF6C5CE7)),
            ),
            const SizedBox(height: 20),
            const Text('Нет доступных заказов', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF2D3436))),
            const SizedBox(height: 8),
            const Text('Загляните позже', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF636E72))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOpenOrders,
      color: const Color(0xFF6C5CE7),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _openOrders.length,
        itemBuilder: (ctx, i) {
          final order = _openOrders[i];
          return _buildJobCard(order);
        },
      ),
    );
  }

  Widget _buildJobCard(Order order) {
    final pricingMode = order.specification?.pricingMode;
    final fixedPrice = order.specification?.price;
    final maxPrice = order.specification?.maxPrice;
    final images = order.imageObjectNames ?? [];

    String priceText;
    if (pricingMode == 'FIXED' && fixedPrice != null) {
      priceText = '${fixedPrice.toInt()} ₸';
    } else if (pricingMode == 'BIDDING' && fixedPrice != null) {
      priceText = 'от ${fixedPrice.toInt()} ₸';
    } else if (pricingMode == 'BIDDING' && maxPrice != null) {
      priceText = 'до ${maxPrice.toInt()} ₸';
    } else {
      priceText = '${order.budget?.toInt() ?? 0} ₸';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('${RouteNames.jobDetails}/${order.id}'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF8B7FF0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(CupertinoIcons.wand_stars, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.serviceName,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: Color(0xFF2D3436)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.location, size: 13, color: Color(0xFFB2BEC3)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    order.address,
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: Color(0xFF636E72)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const StatusBadge(status: 'OPEN'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ✅ Мини-галерея фото
                  if (images.isNotEmpty) ...[
                    SizedBox(
                      height: 72,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length > 4 ? 4 : images.length,
                        itemBuilder: (context, index) {
                          final imageUrl = images[index];
                          return Container(
                            width: 72,
                            height: 72,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDFE6E9), width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl.startsWith('http')
                                    ? imageUrl
                                    : 'http://localhost:8080/api/files/$imageUrl',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: const Color(0xFFF1F2F6),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFFF1F2F6),
                                  child: const Icon(CupertinoIcons.photo, size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      _jobInfoChip(CupertinoIcons.calendar, '${order.orderDate.day}.${order.orderDate.month}.${order.orderDate.year}'),
                      const SizedBox(width: 8),
                      _jobInfoChip(null, priceText, isHighlight: true), // ✅ Убрали иконку
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF8B7FF0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Откликнуться',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _jobInfoChip(IconData? icon, String text, {bool isHighlight = false}) {
    final primaryColor = const Color(0xFF6C5CE7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight ? primaryColor.withOpacity(0.08) : const Color(0xFFF1F2F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: isHighlight ? primaryColor : const Color(0xFF636E72)),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isHighlight ? primaryColor : const Color(0xFF2D3436),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> statusConfig = {
      'OPEN': {'label': 'Открыт', 'color': const Color(0xFF00CEC9)},
      'PENDING': {'label': 'Ожидает', 'color': const Color(0xFFFFA94D)},
      'ACCEPTED': {'label': 'Принят', 'color': const Color(0xFF0984E3)},
      'IN_PROGRESS': {'label': 'В работе', 'color': const Color(0xFF6C5CE7)},
      'COMPLETED': {'label': 'Завершен', 'color': const Color(0xFF20BF6B)},
      'CANCELLED': {'label': 'Отменен', 'color': const Color(0xFFEB3B5A)},
    };

    final config = statusConfig[status] ?? {'label': status, 'color': Colors.grey};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config['label'],
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: config['color'],
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}