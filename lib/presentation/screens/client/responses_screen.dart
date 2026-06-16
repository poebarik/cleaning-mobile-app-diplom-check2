// lib/presentation/screens/client/responses_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/response_repository.dart';
import '../../../data/models/order/order_response.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../routes/route_names.dart';

class ResponsesScreen extends ConsumerStatefulWidget {
  final int orderId;
  final double? orderBudget;

  const ResponsesScreen({
    super.key,
    required this.orderId,
    this.orderBudget,
  });

  @override
  ConsumerState<ResponsesScreen> createState() => _ResponsesScreenState();
}

class _ResponsesScreenState extends ConsumerState<ResponsesScreen> {
  final ResponseRepository _repository = ResponseRepository();
  List<OrderResponse> _responses = [];
  bool _isLoading = true;
  int? _selectedResponseId;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    setState(() => _isLoading = true);
    try {
      final responses = await _repository.getResponsesForOrder(widget.orderId);
      setState(() {
        _responses = responses.where((r) => r.status == 'PENDING').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка загрузки: $e');
      }
    }
  }

  Future<void> _selectCleaner(int responseId) async {
    setState(() => _isSelecting = true);
    try {
      await _repository.selectCleaner(widget.orderId, responseId);
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Клинер выбран!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    } finally {
      setState(() => _isSelecting = false);
    }
  }

  void _showConfirmDialog(OrderResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Выбрать клинера'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Вы уверены, что хотите выбрать ${response.cleanerName}?'),
            const SizedBox(height: 8),
            Text(
              'Цена: ${response.priceOffer.toInt()} ₸',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _selectCleaner(response.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }

  void _viewCleanerProfile(OrderResponse response) {
    context.push('/profile/${response.userId}');  // ✅ API должен возвращать userId
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Отклики клинеров', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadResponses,
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer()
          : _responses.isEmpty
          ? _buildEmpty()
          : Column(
        children: [
          if (widget.orderBudget != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ваш бюджет: ${widget.orderBudget!.toInt()} ₸',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _responses.length,
              itemBuilder: (context, index) => _buildResponseCard(_responses[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(OrderResponse response) {
    final isPriceAboveBudget = widget.orderBudget != null && response.priceOffer > widget.orderBudget!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Шапка с аватаркой и именем
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватарка
                GestureDetector(
                  onTap: () => _viewCleanerProfile(response),
                  child: Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                          image: response.cleanerAvatar != null && response.cleanerAvatar!.isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(response.cleanerAvatar!),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: response.cleanerAvatar == null || response.cleanerAvatar!.isEmpty
                            ? CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            response.cleanerName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        )
                            : null,
                      ),
                      // Бейдж верификации
                      if (response.isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              response.cleanerName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (response.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Верифицирован',
                                style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rate_rounded, size: 16, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            response.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.cleaning_services_rounded, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            '${response.completedOrders} уборок',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Информация о предложении
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPriceAboveBudget ? Colors.red.withOpacity(0.05) : AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPriceAboveBudget ? Colors.red.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.attach_money_rounded,
                    size: 20,
                    color: isPriceAboveBudget ? Colors.red : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Предложенная цена',
                        style: TextStyle(fontSize: 11, color: isPriceAboveBudget ? Colors.red : AppColors.textHint),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${response.priceOffer.toInt()} ₸',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPriceAboveBudget ? Colors.red : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPriceAboveBudget)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Выше бюджета',
                      style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),

          // Сообщение от клинера
          if (response.message != null && response.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textHint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        response.message!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Кнопки действий
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewCleanerProfile(response),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Посмотреть профиль'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSelecting ? null : () => _showConfirmDialog(response),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSelecting && _selectedResponseId == response.id
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Выбрать'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 220,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const ShimmerLoadingCard(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет откликов',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Клинеры еще не откликнулись на ваш заказ',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class ShimmerLoadingCard extends StatelessWidget {
  const ShimmerLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: double.infinity, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 100, color: Colors.grey[300]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 60, width: double.infinity, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Container(height: 40, color: Colors.grey[300])),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 40, color: Colors.grey[300])),
            ],
          ),
        ],
      ),
    );
  }
}