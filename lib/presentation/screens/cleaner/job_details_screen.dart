// lib/presentation/screens/cleaner/job_details_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

      final pricingMode = order.specification?.pricingMode;
      final fixedPrice = order.specification?.price;
      if (pricingMode == 'FIXED' && fixedPrice != null) {
        _priceController.text = fixedPrice.toInt().toString();
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ─── Действия в зависимости от типа заказа ──────────────────────

  // ✅ Для MARKETPLACE - отклик с ценой
  Future<void> _respondMarketplace() async {
    final pricingMode = _order?.specification?.pricingMode;
    final fixedPrice = _order?.specification?.price;
    final isFixed = pricingMode == 'FIXED';

    double price;
    if (isFixed && fixedPrice != null) {
      price = fixedPrice;
    } else {
      if (_priceController.text.isEmpty) {
        CustomSnackbar.showError(context, 'Введите вашу цену');
        return;
      }
      price = double.parse(_priceController.text);
    }

    final message = _messageController.text.isEmpty
        ? 'Готов выполнить уборку'
        : _messageController.text;

    if (isFixed && fixedPrice != null && price != fixedPrice) {
      CustomSnackbar.showError(
          context,
          '⚠️ У заказа фиксированная цена ${fixedPrice.toInt()} ₸. Вы можете откликнуться только с этой ценой.'
      );
      return;
    }

    final maxPrice = _order?.specification?.maxPrice;
    if (!isFixed && pricingMode == 'BIDDING' && maxPrice != null && price > maxPrice) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Превышение максимальной цены'),
          content: Text(
            'Ваша цена (${price.toStringAsFixed(0)} ₸) превышает '
                'максимальную цену клиента (${maxPrice.toStringAsFixed(0)} ₸).\n\n'
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
          OrderAction.respond,  // ✅ Для MARKETPLACE
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
        CustomSnackbar.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ✅ Для COMPANY_ASSIGNED - принятие заказа (используем assignByManager)
  Future<void> _acceptCompanyOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Принять заказ', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          'Вы уверены, что хотите принять заказ "${_order?.serviceName}"?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20BF6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Принять', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      await OrderRepository().executeAction(
          widget.jobId,
          OrderAction.assignByManager,  // ✅ Для COMPANY_ASSIGNED
          {}
      );

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Заказ принят!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ✅ Для DIRECT_INVITATION - принятие приглашения
  Future<void> _acceptDirectInvitation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Принять приглашение', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          'Вы уверены, что хотите принять приглашение на заказ "${_order?.serviceName}"?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF20BF6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Принять', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      await OrderRepository().executeAction(
          widget.jobId,
          OrderAction.acceptInvitation,  // ✅ Для DIRECT_INVITATION - ПРИНЯТЬ
          {}
      );

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Приглашение принято!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ✅ Для DIRECT_INVITATION - отклонение приглашения
  Future<void> _declineDirectInvitation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Отклонить приглашение', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text(
          'Вы уверены, что хотите отклонить приглашение на заказ "${_order?.serviceName}"?',
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEB3B5A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Отклонить', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      await OrderRepository().executeAction(
          widget.jobId,
          OrderAction.declineInvitation,  // ✅ Для DIRECT_INVITATION - ОТКЛОНИТЬ
          {}
      );

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Приглашение отклонено');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ✅ Для DIRECT_INVITATION - встречное предложение
  Future<void> _counterOfferDirectInvitation() async {
    final priceController = TextEditingController(
      text: _order?.specification?.price?.toInt().toString() ?? '',
    );
    final messageController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '💰 Встречное предложение',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Предложите свою цену',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Ваша цена (₸)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Комментарий (необязательно)',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Сообщение',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (price == null || price <= 0) {
                CustomSnackbar.showError(context, 'Введите корректную цену');
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Отправить', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      final price = double.parse(priceController.text);
      final message = messageController.text;

      setState(() => _isSubmitting = true);

      try {
        await OrderRepository().executeAction(
            widget.jobId,
            OrderAction.counterOffer,  // ✅ Для DIRECT_INVITATION - ВСТРЕЧНОЕ ПРЕДЛОЖЕНИЕ
            {
              'priceOffer': price,
              'message': message,
            }
        );

        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Встречное предложение отправлено!');
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          CustomSnackbar.showError(context, 'Ошибка: ${e.toString()}');
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)))
          : _error != null
          ? _buildError()
          : _order == null
          ? const Center(child: Text('Заказ не найден', style: TextStyle(fontFamily: 'Poppins')))
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
                      if (_order!.description != null && _order!.description!.isNotEmpty) ...[
                        _buildDescriptionCard(),
                        const SizedBox(height: 16),
                      ],
                      if (_order!.imageObjectNames != null && _order!.imageObjectNames!.isNotEmpty) ...[
                        _buildImagesCard(),
                        const SizedBox(height: 16),
                      ],
                      if (_order!.specification != null) ...[
                        _buildSpecificationCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildActionCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
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
      backgroundColor: const Color(0xFF6C5CE7),
      elevation: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3436), size: 16),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF8B7FF0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _order!.serviceName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      _buildOrderTypeBadge(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.location_solid, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _order!.address,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

  Widget _buildOrderTypeBadge() {
    final orderType = _order?.orderType ?? 'MARKETPLACE';
    String label;
    Color color;

    switch (orderType) {
      case 'COMPANY_ASSIGNED':
        label = 'От компании';
        color = const Color(0xFF0984E3);
        break;
      case 'DIRECT_INVITATION':
        label = 'Приглашение';
        color = const Color(0xFF6C5CE7);
        break;
      default:
        label = 'Маркетплейс';
        color = const Color(0xFF20BF6B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final pricingMode = _order?.specification?.pricingMode;
    final fixedPrice = _order?.specification?.price;
    final maxPrice = _order?.specification?.maxPrice;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF2D3436),
                ),
              ),
              StatusBadge(status: _order!.status),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow('Тип заказа', _getOrderTypeLabel(_order?.orderType ?? 'MARKETPLACE')),
          _infoRow('Дата', '${_order!.orderDate.day}.${_order!.orderDate.month}.${_order!.orderDate.year}'),
          _infoRow('Время', '${_order!.orderDate.hour.toString().padLeft(2, '0')}:${_order!.orderDate.minute.toString().padLeft(2, '0')}'),
          if (pricingMode == 'FIXED' && fixedPrice != null)
            _infoRow('Фиксированная цена', '${fixedPrice.toInt()} ₸', isHighlight: true),
          if (pricingMode == 'BIDDING' && fixedPrice != null)
            _infoRow('Бюджет', '${fixedPrice.toInt()} ₸', isHighlight: false),
          if (pricingMode == 'BIDDING' && maxPrice != null)
            _infoRow('Макс. цена', '${maxPrice.toInt()} ₸', isHighlight: true),
          if (_order!.clientName != null)
            _infoRow('Клиент', _order!.clientName!),
          _infoRow('Режим цены', pricingMode == 'FIXED' ? 'Фиксированная' : 'Торг', isHighlight: false),
        ],
      ),
    );
  }

  String _getOrderTypeLabel(String type) {
    switch (type) {
      case 'COMPANY_ASSIGNED': return 'Через компанию';
      case 'DIRECT_INVITATION': return 'Прямое приглашение';
      default: return 'Маркетплейс';
    }
  }

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    final primaryColor = const Color(0xFF6C5CE7);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB2BEC3),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
                    color: isHighlight ? primaryColor : const Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Описание',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _order!.description!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF636E72),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCard() {
    final images = _order!.imageObjectNames!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Фотографии',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final imageUrl = images[index];
                final fullUrl = imageUrl.startsWith('http')
                    ? imageUrl
                    : 'http://localhost:8080/api/files/$imageUrl';
                return Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDFE6E9), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: fullUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFFF1F2F6),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFFF1F2F6),
                        child: const Icon(CupertinoIcons.photo, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationCard() {
    final spec = _order!.specification!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Детали уборки',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 12),
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
            _specRow('Животные', spec.hasPets! ? 'Есть' : 'Нет'),
          if (spec.notes != null && spec.notes!.isNotEmpty)
            _specRow('Примечания', spec.notes!),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB2BEC3),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action Card ──────────────────────────────────────────────────

  Widget _buildActionCard() {
    final orderType = _order?.orderType ?? 'MARKETPLACE';

    switch (orderType) {
      case 'COMPANY_ASSIGNED':
        return _buildCompanyAssignedCard();
      case 'DIRECT_INVITATION':
        return _buildDirectInvitationCard();
      default:
        return _buildMarketplaceCard();
    }
  }

  // ✅ MARKETPLACE - отклик с ценой
  Widget _buildMarketplaceCard() {
    final pricingMode = _order?.specification?.pricingMode;
    final fixedPrice = _order?.specification?.price;
    final isFixed = pricingMode == 'FIXED';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ваш отклик',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 14),
          if (isFixed && fixedPrice != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFDFE6E9), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.money_rubl, color: Color(0xFF6C5CE7)),
                  const SizedBox(width: 8),
                  Text(
                    'Фиксированная цена: ${fixedPrice.toInt()} ₸',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0984E3).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF0984E3).withOpacity(0.15)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.info, size: 16, color: Color(0xFF0984E3)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'У заказа фиксированная цена. Изменение стоимости при отклике недоступно.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF0984E3), fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            _styledField(
              _priceController,
              'Ваша цена (₸)',
              keyboardType: TextInputType.number,
            ),
            if (_order!.specification?.maxPrice != null)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  'Максимальная цена клиента: ${_order!.specification!.maxPrice!.toInt()} ₸',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFFFA94D), fontFamily: 'Poppins', fontWeight: FontWeight.w700),
                ),
              ),
          ],
          const SizedBox(height: 14),
          _styledField(
            _messageController,
            'Сообщение клиенту',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ✅ COMPANY_ASSIGNED - просто принять
  Widget _buildCompanyAssignedCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF0984E3).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.building_2_fill, color: Color(0xFF0984E3), size: 20),
              SizedBox(width: 10),
              Text(
                'Заказ от компании',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF0984E3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Этот заказ назначен вам компанией. Просто примите его, чтобы начать работу.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DIRECT_INVITATION - принять/отклонить/предложить цену
  Widget _buildDirectInvitationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F0FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.person_crop_circle_badge_plus, color: Color(0xFF6C5CE7), size: 20),
              SizedBox(width: 10),
              Text(
                'Прямое приглашение',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Клиент пригласил вас лично. Вы можете принять, отклонить или предложить свою цену.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _counterOfferDirectInvitation,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFFFFA94D), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '💰 Предложить цену',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFFFFA94D)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _acceptDirectInvitation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: const Color(0xFF20BF6B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '✅ Принять',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _declineDirectInvitation,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Color(0xFFEB3B5A), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '❌ Отклонить',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Color(0xFFEB3B5A)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _styledField(TextEditingController ctrl, String hint, {int maxLines = 1, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Color(0xFF2D3436), fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFFB2BEC3), fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ─── Bottom Bar ────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    final orderType = _order?.orderType ?? 'MARKETPLACE';
    final isFixed = _order?.specification?.pricingMode == 'FIXED';

    String buttonText;
    VoidCallback? onPressed;
    bool showLoading = _isSubmitting;

    switch (orderType) {
      case 'COMPANY_ASSIGNED':
        buttonText = '✅ Принять заказ';
        onPressed = _acceptCompanyOrder;
        break;
      case 'DIRECT_INVITATION':
        buttonText = '✅ Принять приглашение';
        onPressed = _acceptDirectInvitation;
        break;
      default:
        buttonText = isFixed ? 'Откликнуться' : 'Отправить отклик';
        onPressed = _respondMarketplace;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFF8B7FF0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: showLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: showLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : Text(
              buttonText,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Остальные методы ─────────────────────────────────────────────

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

  Widget _buildError() {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EFF8),
        elevation: 0,
        title: const Text('Детали заказа', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 64, color: Color(0xFFEB3B5A)),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF636E72), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadJob,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Повторить', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> statusConfig = {
      'OPEN': {'label': 'Открыт', 'color': const Color(0xFF00CEC9)},
      'PENDING': {'label': 'Ожидает', 'color': const Color(0xFFFFA94D)},
      'ACCEPTED': {'label': 'Принят', 'color': const Color(0xFF0984E3)},
      'IN_PROGRESS': {'label': 'В работе', 'color': const Color(0xFF6C5CE7)},
      'COMPLETED': {'label': 'Завершен', 'color': const Color(0xFF20BF6B)},
      'CANCELLED': {'label': 'Отменен', 'color': const Color(0xFFEB3B5A)},
    };

    final config = statusConfig[status] ?? {'label': status, 'color': Colors.grey};
    final color = config['color'] as Color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config['label'],
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}