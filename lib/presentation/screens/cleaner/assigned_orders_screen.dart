import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/enums/order_action.dart';
import '../../../data/models/order/order.dart';

class AssignedOrdersScreen extends ConsumerStatefulWidget {
  const AssignedOrdersScreen({super.key});

  @override
  ConsumerState<AssignedOrdersScreen> createState() => _AssignedOrdersScreenState();
}

class _AssignedOrdersScreenState extends ConsumerState<AssignedOrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final repository = OrderRepository();
      final orders = await repository.getCleanerOrders();
      setState(() { _orders = orders; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) CustomSnackbar.showError(context, 'Ошибка: $e');
    }
  }

  Future<void> _updateStatus(int orderId, OrderAction action, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('Подтвердить действие "$label"?', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Подтвердить')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await OrderRepository().executeAction(orderId, action, {});
      if (mounted) { CustomSnackbar.showSuccess(context, 'Статус обновлён'); _loadOrders(); }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Мои заказы', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer()
          : _orders.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
        onRefresh: _loadOrders,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: _orders.length,
          itemBuilder: (ctx, i) => _buildOrderCard(_orders[i]),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final canStart = order.status == 'ACCEPTED';
    final canComplete = order.status == 'IN_PROGRESS';

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
                          Text('Заказ № ${order.id}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
                        ],
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(order.address, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
                    Text(
                      '${order.orderDate.day}.${order.orderDate.month}.${order.orderDate.year}',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '${order.budget} ₽',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                    ),
                  ],
                ),
                if (canStart || canComplete) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (canStart)
                        Expanded(
                          child: _actionButton(
                            label: 'Начать работу',
                            icon: Icons.play_arrow_rounded,
                            color: AppColors.secondary,
                            onTap: () => _updateStatus(order.id, OrderAction.start, 'Начать работу'),
                          ),
                        ),
                      if (canComplete)
                        Expanded(
                          child: _actionButton(
                            label: 'Завершить',
                            icon: Icons.check_rounded,
                            color: AppColors.success,
                            onTap: () => _updateStatus(order.id, OrderAction.complete, 'Завершить'),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 130,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
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
            child: const Icon(Icons.work_off_rounded, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text('Нет назначенных заказов', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Откликнитесь на доступные заказы', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}