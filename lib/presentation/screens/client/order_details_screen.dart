import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../data/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final int orderId;
  final Map<String, dynamic>? orderData;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.orderData,
  });

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.orderData != null) {
      _order = widget.orderData;
      _isLoading = false;
    } else {
      _loadOrderDetails();
    }
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = DioClient.instance;
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.orders}/${widget.orderId}',
      );

      print('Order details response: ${response.data}');

      if (response.statusCode == 200) {
        setState(() {
          _order = response.data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (e) {
      print('Error loading order details: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали заказа'),
        elevation: 0,
      ),
      body: _isLoading
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
              onPressed: _loadOrderDetails,
              child: const Text('Повторить'),
            ),
          ],
        ),
      )
          : _order == null
          ? const Center(child: Text('Заказ не найден'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Заказ #${_order!['id']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(_order!['status'] ?? 'PENDING'),
              ],
            ),
            const Divider(),
            _buildInfoRow('Услуга', _order!['serviceName'] ?? 'Не указана'),
            _buildInfoRow('Адрес', _order!['address'] ?? 'Не указан'),
            _buildInfoRow('Дата', _formatDate(_order!['orderDate'])),
            if (_order!['budget'] != null)
              _buildInfoRow('Бюджет', '${_order!['budget']} ₽'),
            if (_order!['cleanerName'] != null)
              _buildInfoRow('Клинер', _order!['cleanerName']),
            if (_order!['description'] != null && _order!['description'] != '') ...[
              const SizedBox(height: 8),
              const Text(
                'Описание',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(_order!['description']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final status = _order!['status'];
    final steps = [
      {'status': 'PENDING', 'title': 'Заказ создан', 'icon': Icons.create},
      {'status': 'ACCEPTED', 'title': 'Принят', 'icon': Icons.check_circle},
      {'status': 'IN_PROGRESS', 'title': 'В процессе', 'icon': Icons.play_circle},
      {'status': 'COMPLETED', 'title': 'Завершен', 'icon': Icons.verified},
    ];

    final currentIndex = steps.indexWhere((step) => step['status'] == status);
    if (currentIndex == -1) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статус заказа',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                      child: Icon(
                        step['icon'] as IconData,
                        size: 18,
                        color: isCompleted ? Colors.white : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step['title'] as String,
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
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