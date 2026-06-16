// lib/presentation/screens/cleaner/assigned_orders_screen.dart
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
  String _filter = 'ALL'; // ALL, ACTIVE, COMPLETED

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

      // Фильтрация заказов
      List<Order> filteredOrders = orders;
      if (_filter == 'ACTIVE') {
        filteredOrders = orders.where((o) =>
        o.status != 'COMPLETED' && o.status != 'CANCELLED'
        ).toList();
      } else if (_filter == 'COMPLETED') {
        filteredOrders = orders.where((o) =>
        o.status == 'COMPLETED' || o.status == 'CANCELLED'
        ).toList();
      }

      setState(() {
        _orders = filteredOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) CustomSnackbar.showError(context, 'Ошибка: $e');
    }
  }

  Future<void> _updateStatus(int orderId, OrderAction action, String label, {Map<String, dynamic>? payload}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('Подтвердить действие "$label"?', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Подтвердить', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await OrderRepository().executeAction(orderId, action, payload ?? {});
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Статус обновлён');
        _loadOrders();
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Ошибка: $e');
    }
  }

  Future<void> _showCancelDialog(int orderId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Отмена заказа', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите причину отмены:', style: TextStyle(fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Причина отмены',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Отменить', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(
        orderId,
        OrderAction.cancel,
        'Отмена заказа',
        payload: {'reason': reasonController.text.isNotEmpty ? reasonController.text : 'Не указана'},
      );
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
          // Фильтр
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
            onSelected: (value) {
              setState(() => _filter = value);
              _loadOrders();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ALL', child: Text('Все заказы')),
              const PopupMenuItem(value: 'ACTIVE', child: Text('Активные')),
              const PopupMenuItem(value: 'COMPLETED', child: Text('Завершенные')),
            ],
          ),
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
    final statusInfo = _getStatusInfo(order.status);
    final actions = _getAvailableActions(order.status);

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
                          Text(
                            order.serviceName,
                            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Заказ № ${order.id}',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(order.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textHint),
                    const SizedBox(width: 6),
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
                      '${order.budget?.toInt() ?? 0} ₸',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primary),
                    ),
                  ],
                ),
                if (order.description != null && order.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.description!,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: actions.map((action) => _buildActionButton(order.id, action)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(int orderId, Map<String, dynamic> action) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 56) / 2 - 4,
      child: GestureDetector(
        onTap: () {
          if (action['action'] == OrderAction.cancel) {
            _showCancelDialog(orderId);
          } else {
            _updateStatus(orderId, action['action'], action['label']);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: (action['color'] as Color).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action['icon'], size: 16, color: action['color']),
              const SizedBox(width: 6),
              Text(
                action['label'],
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 13, color: action['color']),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final info = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info['color'].withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        info['label'],
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: info['color'], fontFamily: 'Poppins'),
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableActions(String status) {
    final actions = <Map<String, dynamic>>[];

    switch (status) {
      case 'ASSIGNED':
      case 'ACCEPTED':
        actions.add({
          'action': OrderAction.start,
          'label': 'Начать работу',
          'icon': Icons.play_arrow_rounded,
          'color': AppColors.secondary,
        });
        actions.add({
          'action': OrderAction.cancel,
          'label': 'Отменить',
          'icon': Icons.cancel_rounded,
          'color': Colors.red,
        });
        break;

      case 'IN_PROGRESS':
        actions.add({
          'action': OrderAction.complete,
          'label': 'Завершить',
          'icon': Icons.check_rounded,
          'color': AppColors.success,
        });
        actions.add({
          'action': OrderAction.cancel,
          'label': 'Отменить',
          'icon': Icons.cancel_rounded,
          'color': Colors.red,
        });
        break;

      case 'PENDING':
        actions.add({
          'action': OrderAction.acceptInvitation,
          'label': 'Принять',
          'icon': Icons.check_circle_rounded,
          'color': AppColors.success,
        });
        actions.add({
          'action': OrderAction.declineInvitation,
          'label': 'Отклонить',
          'icon': Icons.cancel_rounded,
          'color': Colors.red,
        });
        actions.add({
          'action': OrderAction.counterOffer,
          'label': 'Предложить цену',
          'icon': Icons.currency_exchange,
          'color': AppColors.warning,
        });
        break;
    }

    return actions;
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'PENDING':
        return {'label': 'Ожидает', 'color': AppColors.warning};
      case 'ASSIGNED':
        return {'label': 'Назначен', 'color': AppColors.info};
      case 'ACCEPTED':
        return {'label': 'Принят', 'color': AppColors.secondary};
      case 'IN_PROGRESS':
        return {'label': 'В работе', 'color': AppColors.primary};
      case 'COMPLETED':
        return {'label': 'Завершен', 'color': AppColors.success};
      case 'CANCELLED':
        return {'label': 'Отменен', 'color': Colors.red};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 150,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const ShimmerLoading(),
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

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 46, height: 46, color: Colors.grey[300]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 14, width: double.infinity, color: Colors.grey[300]),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 80, color: Colors.grey[300]),
                  ],
                ),
              ),
              Container(width: 60, height: 24, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 12, width: double.infinity, color: Colors.grey[300]),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(height: 12, width: 100, color: Colors.grey[300]),
              const Spacer(),
              Container(height: 12, width: 60, color: Colors.grey[300]),
            ],
          ),
        ],
      ),
    );
  }
}