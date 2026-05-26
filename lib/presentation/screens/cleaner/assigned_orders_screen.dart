import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../data/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../routes/route_names.dart';

class AssignedOrdersScreen extends ConsumerStatefulWidget {
  const AssignedOrdersScreen({super.key});

  @override
  ConsumerState<AssignedOrdersScreen> createState() => _AssignedOrdersScreenState();
}

class _AssignedOrdersScreenState extends ConsumerState<AssignedOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssignedOrders();
  }

  Future<void> _loadAssignedOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = DioClient.instance;
      // Используем правильный endpoint: /api/orders/cleaner
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.cleanerOrders}',
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        // Обрабатываем ответ в зависимости от формата
        List<Map<String, dynamic>> ordersList = [];
        if (response.data is List) {
          ordersList = List<Map<String, dynamic>>.from(response.data);
        } else if (response.data is Map && response.data['content'] is List) {
          ordersList = List<Map<String, dynamic>>.from(response.data['content']);
        }

        setState(() {
          _orders = ordersList;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    try {
      final dio = DioClient.instance;
      final response = await dio.patch(
        '${ApiConstants.baseUrl}${ApiConstants.orders}/$orderId/status',
        data: {'status': newStatus},
      );

      if (response.statusCode == 200) {
        CustomSnackbar.showSuccess(context, 'Статус заказа обновлен');
        _loadAssignedOrders();
      }
    } catch (e) {
      CustomSnackbar.showError(context, 'Ошибка обновления статуса: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignedOrders,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssignedOrders,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAssignedOrders,
                child: const Text('Повторить'),
              ),
            ],
          ),
        )
            : _orders.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('У вас пока нет назначенных заказов'),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            return _buildOrderCard(order);
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? 'PENDING';
    final canStart = status == 'ACCEPTED' || status == 'PENDING';
    final canComplete = status == 'IN_PROGRESS';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push(
            '${RouteNames.orderDetails}/${order['id']}',
            extra: order,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Заказ #${order['id']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order['address'] ?? 'Адрес не указан',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(order['orderDate']),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Клиент: ${order['clientName'] ?? 'Не указан'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              if (canStart || canComplete) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (canStart)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateOrderStatus(order['id'], 'IN_PROGRESS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Начать работу'),
                        ),
                      ),
                    if (canStart && canComplete) const SizedBox(width: 12),
                    if (canComplete)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateOrderStatus(order['id'], 'COMPLETED'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Завершить'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        text = 'В ожидании';
        break;
      case 'ACCEPTED':
        color = Colors.green;
        text = 'Принят';
        break;
      case 'IN_PROGRESS':
        color = Colors.blue;
        text = 'В процессе';
        break;
      case 'COMPLETED':
        color = Colors.teal;
        text = 'Завершен';
        break;
      case 'CANCELLED':
        color = Colors.red;
        text = 'Отменен';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Дата не указана';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return dateString;
    }
  }
}