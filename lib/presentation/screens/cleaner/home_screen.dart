import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/route_names.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/models/order/order.dart';
import '../../../data/models/order/marketplace_order.dart';
import '../../../shared/widgets/marketplace_order_card.dart';
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
      backgroundColor: AppColors.background,
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(String firstName) {
    return GradientContainer(
      colors: AppColors.gradient,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'K',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Добро пожаловать!', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')),
                    Text(firstName, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                  ],
                ),
              ),
              _headerButton(Icons.notifications_none_rounded, () => context.push(RouteNames.notifications)),
              const SizedBox(width: 8),
              _headerButton(Icons.chat_bubble_outline_rounded, () => context.push(RouteNames.chatList)),
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
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _statCard('${_openOrders.length}', 'Заказов', Icons.work_rounded, AppColors.primary),
          const SizedBox(width: 12),
          _statCard('4.9', 'Рейтинг', Icons.star_rounded, const Color(0xFFFFB800)),
          const SizedBox(width: 12),
          _statCard('12', 'Выполнено', Icons.check_circle_rounded, AppColors.success),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Доступные заказы', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
          GestureDetector(
            onTap: _loadOpenOrders,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('Обновить', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadOpenOrders, child: const Text('Повторить')),
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
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.work_off_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('Нет доступных заказов', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Загляните позже', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadOpenOrders,
      color: AppColors.primary,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('${RouteNames.jobDetails}/${order.id}'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.serviceName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textHint),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  order.address,
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    _jobInfoChip(Icons.calendar_today_rounded, '${order.orderDate.day}.${order.orderDate.month}.${order.orderDate.year}'),
                    const SizedBox(width: 10),
                    _jobInfoChip(Icons.attach_money_rounded, '${order.budget} ₽', isHighlight: true),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Откликнуться', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _jobInfoChip(IconData icon, String text, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primary.withOpacity(0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isHighlight ? AppColors.primary : AppColors.textHint),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: isHighlight ? AppColors.primary : AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Главная', 0),
              _navItem(Icons.work_rounded, 'Заказы', 1),
              _navItem(Icons.mail_rounded, 'Приглашения', 2),
              _navItem(Icons.person_rounded, 'Профиль', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _navIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _navIndex = index);
        if (index == 1) context.push(RouteNames.assignedOrders);
        if (index == 2) context.push(RouteNames.myInvitations);
        if (index == 3) context.push(RouteNames.profile);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: isSelected ? AppColors.primary : AppColors.textHint),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: isSelected ? AppColors.primary : AppColors.textHint, fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}