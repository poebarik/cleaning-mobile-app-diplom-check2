import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/route_names.dart';
import '../../../data/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final int orderId;
  final Map<String, dynamic>? orderData;
  const OrderDetailsScreen({super.key, required this.orderId, this.orderData});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;

  final _steps = [
    {'key': 'PENDING', 'label': 'Создан', 'icon': Icons.add_circle_outline_rounded},
    {'key': 'ACCEPTED', 'label': 'Принят', 'icon': Icons.check_circle_outline_rounded},
    {'key': 'IN_PROGRESS', 'label': 'В процессе', 'icon': Icons.autorenew_rounded},
    {'key': 'COMPLETED', 'label': 'Завершён', 'icon': Icons.verified_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.orderData != null) {
      _order = widget.orderData;
      _isLoading = false;
    } else {
      _loadOrder();
    }
  }

  Future<void> _loadOrder() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final dio = DioClient.instance;
      final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.orders}/${widget.orderId}');
      if (response.statusCode == 200) {
        setState(() { _order = response.data; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  int get _currentStepIndex {
    final status = _order?['status'] ?? 'PENDING';
    return _steps.indexWhere((s) => s['key'] == status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? _buildError()
          : _order == null
          ? const Center(child: Text('Заказ не найден'))
          : CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeline(),
                  const SizedBox(height: 20),
                  _buildDetailsCard(),
                  const SizedBox(height: 20),
                  if (_order!['description'] != null && _order!['description'] != '')
                    _buildDescriptionCard(),
                  const SizedBox(height: 20),
                  if (_order!['cleanerName'] != null)
                    _buildCleanerCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _order!['serviceName'] ?? 'Уборка',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Заказ № ${_order!['id']}',
                          style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins'),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: _order!['status'] ?? 'PENDING'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final stepIdx = _currentStepIndex;
    final isCancelled = _order?['status'] == 'CANCELLED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Статус заказа', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          if (isCancelled)
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Заказ отменён', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.error)),
              ],
            )
          else
            Row(
              children: _steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                final isDone = i <= stepIdx;
                final isCurrent = i == stepIdx;
                final isLast = i == _steps.length - 1;

                return Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                gradient: isDone ? const LinearGradient(colors: AppColors.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                                color: isDone ? null : AppColors.divider,
                                shape: BoxShape.circle,
                                border: isCurrent ? Border.all(color: AppColors.primary, width: 2.5) : null,
                              ),
                              child: Icon(
                                step['icon'] as IconData,
                                size: 18,
                                color: isDone ? Colors.white : AppColors.textHint,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step['label'] as String,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                                color: isDone ? AppColors.primary : AppColors.textHint,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Container(
                          height: 2,
                          width: 16,
                          color: i < stepIdx ? AppColors.primary : AppColors.divider,
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Детали', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          _detailRow(Icons.location_on_rounded, 'Адрес', _order!['address'] ?? 'Не указан'),
          _detailRow(Icons.calendar_today_rounded, 'Дата', _formatDate(_order!['orderDate'])),
          if (_order!['budget'] != null)
            _detailRow(Icons.attach_money_rounded, 'Бюджет', '${_order!['budget']} ₽', isHighlight: true),
          if (_order!['fulfillmentType'] != null)
            _detailRow(Icons.category_rounded, 'Тип', _fulfillmentLabel(_order!['fulfillmentType'])),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textHint)),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                  color: isHighlight ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Описание', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          Text(_order!['description'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildCleanerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.05), AppColors.secondary.withOpacity(0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (_order!['cleanerName'] as String? ?? 'К')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ваш клинер', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
                Text(_order!['cleanerName'] ?? '', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _loadOrder, child: const Text('Повторить')),
        ],
      ),
    );
  }

  String _formatDate(String? ds) {
    if (ds == null) return 'Не указана';
    try {
      final d = DateTime.parse(ds);
      return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return ds; }
  }

  String _fulfillmentLabel(String type) {
    switch (type) {
      case 'COMPANY_ASSIGNED': return 'Через компанию';
      case 'MARKETPLACE': return 'Маркетплейс';
      case 'DIRECT_INVITATION': return 'Прямое приглашение';
      default: return type;
    }
  }
}