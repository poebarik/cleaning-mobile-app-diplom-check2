import 'package:flutter/material.dart';
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

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  final List<String> _tabs = ['Все', 'Ожидание', 'В процессе', 'Завершены'];

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
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = DioClient.instance;
      final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.clientOrders}');
      if (response.statusCode == 200) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
      } else {
        throw Exception('Ошибка загрузки');
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Мои заказы', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOrders,
            color: AppColors.primary,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
      ),
      body: _isLoading
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
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) => _buildOrderCard(filtered[i]),
            ),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.createOrder),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Новый заказ', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white)),
        elevation: 4,
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'PENDING';
    final canCancel = status == 'PENDING' || status == 'OPEN';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => context.push('${RouteNames.orderDetails}/${order['id']}', extra: order),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['serviceName'] ?? 'Заказ #${order['id']}',
                            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '№ ${order['id']}',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: AppColors.divider,
                ),
                const SizedBox(height: 14),
                _infoRow(Icons.location_on_rounded, order['address'] ?? 'Адрес не указан'),
                const SizedBox(height: 8),
                _infoRow(Icons.calendar_today_rounded, _formatDate(order['orderDate'])),
                if (order['cleanerName'] != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.person_rounded, 'Клинер: ${order['cleanerName']}'),
                ],
                if (order['budget'] != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(Icons.attach_money_rounded, '${order['budget']} ₽', isPrice: true),
                ],
                if (canCancel) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelOrder(order['id']),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Отменить заказ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
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
        Icon(icon, size: 15, color: AppColors.textHint),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: isPrice ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isPrice ? FontWeight.w700 : FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      final dio = DioClient.instance;
      await dio.patch('${ApiConstants.baseUrl}${ApiConstants.orders}/$orderId/status', data: {'status': 'CANCELLED'});
      if (mounted) { CustomSnackbar.showSuccess(context, 'Заказ отменён'); _loadOrders(); }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Ошибка отмены');
    }
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        height: 140,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _buildError() {
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
          const Text('Что-то пошло не так', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loadOrders, child: const Text('Повторить')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
            child: const Icon(Icons.inbox_rounded, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Здесь пока пусто', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Создайте первый заказ', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  String _formatDate(String? ds) {
    if (ds == null) return 'Дата не указана';
    try {
      final d = DateTime.parse(ds);
      return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ds; }
  }
}