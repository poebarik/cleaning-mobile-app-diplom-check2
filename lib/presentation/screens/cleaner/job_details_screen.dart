import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../data/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/order/marketplace_order.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final int jobId;
  const JobDetailsScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  MarketplaceOrder? _order;
  bool _isLoading = true;
  bool _isResponding = false;
  String? _error;
  final _messageController = TextEditingController();
  final _priceOfferController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadJobDetails();
  }

  Future<void> _loadJobDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dio = DioClient.instance;
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.marketplaceOrders}/${widget.jobId}',
      );

      if (response.statusCode == 200) {
        setState(() {
          _order = MarketplaceOrder.fromJson(response.data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load job details');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _respondToJob() async {
    if (_priceOfferController.text.isEmpty) {
      CustomSnackbar.showError(context, 'Введите цену');
      return;
    }

    setState(() {
      _isResponding = true;
    });

    try {
      final dio = DioClient.instance;
      final response = await dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.marketplaceOrders}/${widget.jobId}/respond',
        data: {
          'message': _messageController.text.isEmpty ? 'Готов выполнить уборку' : _messageController.text,
          'priceOffer': double.parse(_priceOfferController.text),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (context.mounted) {
          CustomSnackbar.showSuccess(context, 'Отклик отправлен!');
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to respond');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResponding = false;
        });
      }
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
              onPressed: _loadJobDetails,
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
            // Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _order!.serviceName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StatusChip(status: _order!.status),
              ],
            ),
            const SizedBox(height: 16),
            // Address
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Адрес',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_order!.address)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Date & Budget
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Дата'),
                        Text(_formatDate(_order!.orderDate)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Бюджет'),
                        Text(
                          '${_order!.budget} Т',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Срок отклика'),
                        Text('${_order!.responseDeadlineDays} дней'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            if (_order!.description != null && _order!.description!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Описание',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_order!.description!),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Response form
            const Text(
              'Откликнуться на заказ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Сообщение',
                hintText: 'Напишите что-то о себе...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceOfferController,
              decoration: const InputDecoration(
                labelText: 'Ваша цена (Т)',
                hintText: 'Предложите свою цену',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            CustomButton(
              onPressed: _respondToJob,
              text: 'Откликнуться',
              isLoading: _isResponding,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} в ${date.hour}:${date.minute}';
  }
}