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

  Future<void> _loadOpenOrders() async {
    setState(() => _isLoading = true);
    try {
      final repository = OrderRepository();
      final orders = await repository.getClientOrders();
      setState(() {
        _orders = orders.where((o) => o.status == 'OPEN').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    }
  }

  Future<void> _respondToOrder(Order order) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
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
            Text('Отклик на заказ #${order.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _priceController,
              label: 'Ваша цена (₽)',
              prefixIcon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _messageController,
              label: 'Сообщение',
              prefixIcon: Icons.message_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            CustomButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitResponse(order.id);
              },
              text: 'Отправить отклик',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitResponse(int orderId) async {
    try {
      final authState = ref.read(authProvider);
      final cleanerId = authState.user?.id;

      final repository = OrderRepository();
      await repository.executeAction(
        orderId,
        OrderAction.respond,
        {
          'cleanerId': cleanerId,
          'priceOffer': double.parse(_priceController.text),
          'message': _messageController.text,
        },
      );

      _priceController.clear();
      _messageController.clear();

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Отклик отправлен!');
        _loadOpenOrders();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступные заказы'),
        elevation: 0,
      ),
      body: _isLoading
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
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('Заказ #${order.id}'),
              subtitle: Text(order.address),
              trailing: ElevatedButton(
                onPressed: () => _respondToOrder(order),
                child: const Text('Откликнуться'),
              ),
            ),
          );
        },
      ),
    );
  }
}