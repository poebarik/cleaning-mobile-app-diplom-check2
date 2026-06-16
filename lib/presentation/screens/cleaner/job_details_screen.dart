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

    final price = double.parse(_priceController.text);
    final message = _messageController.text.isEmpty
        ? 'Готов выполнить уборку'
        : _messageController.text;

    // ✅ ИСПРАВЛЕНО: доступ к maxPrice через specification
    final maxPrice = _order?.specification?.maxPrice;

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

    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authProvider);
      final cleanerId = authState.user?.cleanerId;

      if (cleanerId == null || cleanerId == 0) {
        CustomSnackbar.showError(context, 'Ошибка: не удалось получить ID клинера');
        return;
      }

      await OrderRepository().executeAction(
          widget.jobId,
          OrderAction.respond,
          {
            'priceOffer': price,
            'message': message,
          }
      );

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Отклик отправлен!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('maxPrice') || errorMessage.contains('exceeds')) {
          CustomSnackbar.showError(context, 'Цена превышает максимально допустимую');
        } else {
          CustomSnackbar.showError(context, 'Ошибка: $e');
        }
      }
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
                      if (_order!.specification != null)
                        _buildSpecificationCard(),
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
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10)
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
                end: Alignment.bottomRight
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _order!.serviceName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins'
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                            _order!.address,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontFamily: 'Poppins'
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis
                        ),
                      ),
                    ],
                  ),
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
              const Text(
                'Информация',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary
                ),
              ),
              StatusBadge(status: _order!.status),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow(
              Icons.calendar_today_rounded,
              'Дата',
              '${_order!.orderDate.day}.${_order!.orderDate.month}.${_order!.orderDate.year}'
          ),
          _infoRow(
              Icons.access_time_rounded,
              'Время',
              '${_order!.orderDate.hour.toString().padLeft(2,'0')}:${_order!.orderDate.minute.toString().padLeft(2,'0')}'
          ),
          if (_order!.budget != null)
            _infoRow(Icons.attach_money_rounded, 'Бюджет', '${_order!.budget} ₽', isHighlight: true),
          // ✅ ИСПРАВЛЕНО: доступ к maxPrice через specification
          if (_order!.specification?.maxPrice != null)
            _infoRow(Icons.attach_money_rounded, 'Макс. цена', '${_order!.specification!.maxPrice!.toStringAsFixed(0)} ₽', isHighlight: false),
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
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9)
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  label,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textHint)
              ),
              Text(
                value,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                    color: isHighlight ? AppColors.primary : AppColors.textPrimary
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
          const Text(
            'Описание',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          Text(
              _order!.description!,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary, height: 1.5)
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationCard() {
    final spec = _order!.specification!;
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
          const Text(
            'Детали уборки',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          if (spec.locationType != null)
            _specRow('Тип помещения', _getLocationTypeName(spec.locationType!)),
          if (spec.locationCustom != null)
            _specRow('Тип помещения', spec.locationCustom!),
          if (spec.area != null)
            _specRow('Площадь', '${spec.area} м²'),
          if (spec.cleaningType != null)
            _specRow('Тип уборки', _getCleaningTypeName(spec.cleaningType!)),
          if (spec.rooms != null && spec.rooms!.isNotEmpty)
            _specRow('Комнаты', spec.rooms!.map((r) => _getRoomName(r)).join(', ')),
          if (spec.roomsCustom != null)
            _specRow('Комнаты', spec.roomsCustom!),
          if (spec.additionalServices != null && spec.additionalServices!.isNotEmpty)
            _specRow('Доп. услуги', spec.additionalServices!.map((s) => _getServiceName(s)).join(', ')),
          if (spec.customServices != null && spec.customServices!.isNotEmpty)
            _specRow('Кастомные услуги', spec.customServices!.join(', ')),
          if (spec.inventory != null)
            _specRow('Инвентарь', _getInventoryName(spec.inventory!)),
          if (spec.roomsCount != null)
            _specRow('Комнат', '${spec.roomsCount}'),
          if (spec.bathrooms != null)
            _specRow('Санузлов', '${spec.bathrooms}'),
          if (spec.hasPets != null)
            _specRow('Домашние животные', spec.hasPets! ? 'Есть' : 'Нет'),
          if (spec.notes != null && spec.notes!.isNotEmpty)
            _specRow('Примечания', spec.notes!),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocationTypeName(String type) {
    switch (type) {
      case 'APARTMENT': return 'Квартира';
      case 'HOUSE': return 'Дом';
      case 'OFFICE': return 'Офис';
      case 'COMMERCIAL': return 'Коммерческое';
      case 'CUSTOM': return 'Другое';
      default: return type;
    }
  }

  String _getCleaningTypeName(String type) {
    switch (type) {
      case 'MAINTENANCE': return 'Поддерживающая';
      case 'DEEP_CLEANING': return 'Генеральная';
      case 'AFTER_RENOVATION': return 'После ремонта';
      case 'MOVE_IN': return 'Перед заездом';
      case 'MOVE_OUT': return 'После выезда';
      case 'CUSTOM': return 'Другое';
      default: return type;
    }
  }

  String _getRoomName(String room) {
    switch (room) {
      case 'WHOLE_APARTMENT': return 'Вся квартира';
      case 'KITCHEN': return 'Кухня';
      case 'BATHROOM': return 'Ванная';
      case 'BALCONY': return 'Балкон';
      case 'BEDROOM': return 'Спальня';
      case 'LIVING_ROOM': return 'Гостиная';
      case 'CUSTOM': return 'Другое';
      default: return room;
    }
  }

  String _getServiceName(String service) {
    switch (service) {
      case 'WINDOWS': return 'Мойка окон';
      case 'FRIDGE': return 'Холодильник';
      case 'OVEN': return 'Духовка';
      case 'FURNITURE_CLEANING': return 'Чистка мебели';
      case 'IRONING': return 'Глажка';
      default: return service;
    }
  }

  String _getInventoryName(String inventory) {
    switch (inventory) {
      case 'CLIENT': return 'Клиент предоставит';
      case 'CLEANER': return 'Я предоставлю';
      case 'PARTIAL': return 'Частично';
      default: return inventory;
    }
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
          const Text(
            'Ваш отклик',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          _styledField(
              _priceController,
              'Ваша цена (₽)',
              Icons.attach_money_rounded,
              keyboardType: TextInputType.number
          ),
          // ✅ ИСПРАВЛЕНО: доступ к maxPrice через specification
          if (_order!.specification?.maxPrice != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                'Максимальная цена: ${_order!.specification!.maxPrice!.toStringAsFixed(0)} ₽',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          const SizedBox(height: 12),
          _styledField(
              _messageController,
              'Сообщение клиенту',
              Icons.message_rounded,
              maxLines: 3
          ),
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
                : const Text(
                'Отправить отклик',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)
            ),
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

// Вспомогательный виджет для статуса
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> statusConfig = {
      'OPEN': {'label': 'Открыт', 'color': Colors.green},
      'PENDING': {'label': 'Ожидает', 'color': Colors.orange},
      'ACCEPTED': {'label': 'Принят', 'color': Colors.blue},
      'IN_PROGRESS': {'label': 'В работе', 'color': Colors.purple},
      'COMPLETED': {'label': 'Завершен', 'color': Colors.teal},
      'CANCELLED': {'label': 'Отменен', 'color': Colors.red},
    };

    final config = statusConfig[status] ?? {'label': status, 'color': Colors.grey};

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        config['label'],
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: config['color'],
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}