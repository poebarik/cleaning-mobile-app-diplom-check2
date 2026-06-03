import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/route_names.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/enums/order_action.dart';
import '../../../data/models/order/order.dart';
import '../../providers/auth_provider.dart';

class JobDetailsScreen extends ConsumerStatefulWidget {
  final int jobId;
  const JobDetailsScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {
  Order? _order;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadJob() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final order = await OrderRepository().getOrderById(widget.jobId);
      setState(() { _order = order; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _respond() async {
    if (_priceController.text.isEmpty) {
      CustomSnackbar.showError(context, 'Введите вашу цену');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final cleanerId = (ref.read(authProvider) as AuthStateAuthenticated?)?.user?.id;
      await OrderRepository().executeAction(widget.jobId, OrderAction.respond, {
        'cleanerId': cleanerId,
        'priceOffer': double.parse(_priceController.text),
        'message': _messageController.text.isEmpty ? 'Готов выполнить уборку' : _messageController.text,
      });
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Отклик отправлен!');
        context.pop();
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
          : Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverHeader(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      if (_order!.description != null && _order!.description!.isNotEmpty)
                        _buildDescriptionCard(),
                      const SizedBox(height: 16),
                      _buildRespondCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: AppColors.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(_order!.serviceName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Expanded(child: Text(_order!.address, style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins'), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Информация', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              StatusBadge(status: _order!.status),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.calendar_today_rounded, 'Дата', '${_order!.orderDate.day}.${_order!.orderDate.month}.${_order!.orderDate.year}'),
          _infoRow(Icons.access_time_rounded, 'Время', '${_order!.orderDate.hour.toString().padLeft(2,'0')}:${_order!.orderDate.minute.toString().padLeft(2,'0')}'),
          _infoRow(Icons.attach_money_rounded, 'Бюджет', '${_order!.budget} ₽', isHighlight: true),
          if (_order!.clientName != null)
            _infoRow(Icons.person_outline_rounded, 'Клиент', _order!.clientName!),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textHint)),
              Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500, color: isHighlight ? AppColors.primary : AppColors.textPrimary)),
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
          Text(_order!.description!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildRespondCard() {
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
          const Text('Ваш отклик', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          _styledField(_priceController, 'Ваша цена (₽)', Icons.attach_money_rounded, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _styledField(_messageController, 'Сообщение клиенту', Icons.message_rounded, maxLines: 3),
        ],
      ),
    );
  }

  Widget _styledField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textHint),
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 20, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _respond,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Отправить отклик', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Детали заказа')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadJob, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}