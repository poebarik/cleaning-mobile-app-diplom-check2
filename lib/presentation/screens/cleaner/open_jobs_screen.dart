import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../routes/route_names.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/enums/order_action.dart';
import '../../../data/models/order/order.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class OpenJobsScreen extends ConsumerStatefulWidget {
  const OpenJobsScreen({super.key});

  @override
  ConsumerState<OpenJobsScreen> createState() => _OpenJobsScreenState();
}

class _OpenJobsScreenState extends ConsumerState<OpenJobsScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOpenOrders();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadOpenOrders() async {
    setState(() => _isLoading = true);
    try {
      final repository = OrderRepository();
      final orders = await repository.getOpenMarketplaceOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка загрузки: $e');
      }
    }
  }

  Future<void> _submitResponse(Order order) async {
    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      CustomSnackbar.showError(context, 'Введите корректную цену');
      return;
    }

    final message = _messageController.text.trim().isEmpty
        ? 'Готов(а) выполнить уборку'
        : _messageController.text.trim();

    // ✅ Доступ к maxPrice через specification
    final maxPrice = order.specification?.maxPrice;

    if (maxPrice != null && price > maxPrice) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Превышение максимальной цены'),
          content: Text(
            'Ваша цена (${price.toStringAsFixed(0)} ₽) превышает '
                'максимальную цену клиента (${maxPrice.toStringAsFixed(0)} ₽).\n\n'
                'Клиент не сможет принять ваш отклик. Отправить всё равно?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Отправить'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final cleanerId = authState.user?.cleanerId;

      if (cleanerId == null || cleanerId == 0) {
        CustomSnackbar.showError(context, 'Ошибка: не удалось получить ID клинера');
        return;
      }

      final repository = OrderRepository();
      await repository.executeAction(
        order.id,
        OrderAction.respond,
        {
          'priceOffer': price,
          'message': message,
        },
      );

      _priceController.clear();
      _messageController.clear();

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Отклик отправлен!');
        await _loadOpenOrders();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResponseModal(Order order) {
    _priceController.clear();
    _messageController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Отклик на заказ #${order.id}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.serviceName,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _priceController,
                    label: 'Ваша цена (₽)',
                    prefixIcon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                  // ✅ Отображение maxPrice из specification
                  if (order.specification?.maxPrice != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        'Максимальная цена: ${order.specification!.maxPrice!.toStringAsFixed(0)} ₽',
                        style: const TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _messageController,
                    label: 'Сообщение',
                    prefixIcon: Icons.message_outlined,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _submitResponse(order);
                    },
                    text: 'Отправить отклик',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные заказы'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOpenOrders,
        child: _isLoading
            ? const ShimmerLoading(child: SizedBox(height: 120))
            : _orders.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.work_off_outlined, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Нет доступных заказов'),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orders.length,
          itemBuilder: (context, index) {
            final order = _orders[index];
            final authState = ref.read(authProvider);
            final currentCleanerId = authState.user?.cleanerId;
            final hasResponded = order.responses?.any((r) => r.cleanerId == currentCleanerId) ?? false;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  context.push(
                    '${RouteNames.jobDetails}/${order.id}',
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
                              order.serviceName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (hasResponded)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Вы откликнулись',
                                style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.address,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(order.orderDate),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          if (order.budget != null)
                            Row(
                              children: [
                                const Icon(Icons.attach_money, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  '${order.budget} ₽',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          // ✅ Отображение maxPrice из specification
                          if (order.specification?.maxPrice != null)
                            Row(
                              children: [
                                const Icon(Icons.attach_money, size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text(
                                  'Макс: ${order.specification!.maxPrice!.toStringAsFixed(0)} ₽',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!hasResponded)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _showResponseModal(order),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Откликнуться'),
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.push(
                              '${RouteNames.jobDetails}/${order.id}',
                              extra: order,
                            ),
                            child: const Text('Посмотреть детали'),
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}