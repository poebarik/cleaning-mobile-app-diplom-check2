import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/route_names.dart';
import '../../../data/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/custom_snackbar.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  final List<String> _tabs = ['Все', 'Открыт', 'Ожидание', 'В процессе', 'Завершены'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = DioClient.instance;
      final response = await dio.get(
          '${ApiConstants.baseUrl}${ApiConstants.clientOrders}');
      if (response.statusCode == 200) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
      } else {
        throw Exception('Ошибка загрузки');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _filterOrders(String tab) {
    if (tab == 'Все') return _orders;
    final statusMap = {
      'Ожидание': ['PENDING', 'OPEN'],
      'В процессе': ['ACCEPTED', 'IN_PROGRESS'],
      'Завершены': ['COMPLETED', 'CANCELLED'],
    };
    final statuses = statusMap[tab] ?? [];
    return _orders.where((o) => statuses.contains(o['status'])).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: Column(
        children: [
          // ✅ Header - НЕ СТИКИ
          _buildHeader(),

          // ✅ TabBar - НЕ СТИКИ (скроллится вместе с контентом)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade500,
              labelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: _tabs
                  .map((t) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Tab(text: t),
              ))
                  .toList(),
            ),
          ),

          // ✅ Контент
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _error != null
                ? _buildError()
                : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = _filterOrders(tab);
                if (filtered.isEmpty) return _buildEmpty();
                return RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: const Color(0xFF6C5CE7),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _buildOrderCard(filtered[i]),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ✅ Новый виджет хедера (без SliverAppBar)
  Widget _buildHeader() {
    return Container(
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Мои заказы',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Управляйте своими заказами',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _loadOrders,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => context.push(RouteNames.createOrder),
      backgroundColor: Colors.transparent,
      elevation: 0,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      label: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C5CE7).withOpacity(0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),

      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'PENDING';
    final canCancel = status == 'PENDING' || status == 'OPEN';
    final (statusColor, statusBg, statusLabel) = _getStatusStyle(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.push(
            '${RouteNames.orderDetails}/${order['id']}',
            extra: order,
          ),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [

                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['serviceName'] ?? 'Заказ #${order['id']}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF2D3436),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),

                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(height: 1, color: Colors.grey.shade50),
                const SizedBox(height: 12),
                _infoRow(
                    CupertinoIcons.location,
                    order['address'] ?? 'Адрес не указан'),
                const SizedBox(height: 8),
                _infoRow(
                    CupertinoIcons.calendar,
                    _formatDate(order['orderDate'])),
                if (order['cleanerName'] != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                      CupertinoIcons.person,
                      'Клинер: ${order['cleanerName']}'),
                ],
                if (order['budget'] != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                      CupertinoIcons.money_dollar_circle,
                      '${order['budget']} ₸',
                      isPrice: true),
                ],
                if (canCancel) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelOrder(order['id']),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Отменить заказ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade600,
                        backgroundColor: Colors.red.shade50,
                        side: BorderSide(color: Colors.red.shade100),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool isPrice = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: isPrice
              ? const Color(0xFF6C5CE7)
              : Colors.grey.shade400,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: isPrice
                  ? const Color(0xFF6C5CE7)
                  : Colors.grey.shade600,
              fontWeight: isPrice ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  (Color, Color, String) _getStatusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'OPEN':
        return (const Color(0xFF2E7D32), const Color(0xFFE8F5E9), 'Открыт');
      case 'PENDING':
        return (const Color(0xFFF57F17), const Color(0xFFFFF8E1), 'Ожидание');
      case 'ACCEPTED':
        return (const Color(0xFF2E7D32), const Color(0xFFE8F5E9), 'Принят');
      case 'IN_PROGRESS':
        return (const Color(0xFF1565C0), const Color(0xFFE3F2FD), 'В процессе');
      case 'COMPLETED':
        return (const Color(0xFF2E7D32), const Color(0xFFE8F5E9), 'Завершён');
      case 'CANCELLED':
        return (const Color(0xFFC62828), const Color(0xFFFFEBEE), 'Отменён');
      default:
        return (Colors.grey.shade600, Colors.grey.shade100, status);
    }
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      final dio = DioClient.instance;
      await dio.patch(
        '${ApiConstants.baseUrl}${ApiConstants.orders}/$orderId/actions/status',
        data: {'status': 'CANCELLED'},
      );
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Заказ отменён');
        _loadOrders();
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Ошибка отмены');
    }
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 150,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(50, 50, radius: 14),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(12, 140),
                        const SizedBox(height: 6),
                        _shimmerBox(10, 80),
                      ],
                    ),
                  ),
                  _shimmerBox(24, 64, radius: 12),
                ],
              ),
              const SizedBox(height: 16),
              _shimmerBox(10, double.infinity),
              const SizedBox(height: 8),
              _shimmerBox(10, 180),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double height, double width, {double radius = 8}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 40, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            const Text(
              'Что-то пошло не так',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
              child: const Text(
                'Повторить',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDE9FE), Color(0xFFC4B5FD)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('📋', style: TextStyle(fontSize: 44)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Здесь пока пусто',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте первый заказ и найдите\nлучшего специалиста рядом',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push(RouteNames.createOrder),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Создать заказ',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? ds) {
    if (ds == null) return 'Дата не указана';
    try {
      final d = DateTime.parse(ds);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ds;
    }
  }
}