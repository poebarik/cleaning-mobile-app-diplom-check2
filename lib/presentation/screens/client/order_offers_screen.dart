// lib/presentation/screens/client/order_offers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/response_repository.dart';
import '../../../data/repositories/invitation_repository.dart';
import '../../../data/models/order/order_response.dart';
import '../../../data/models/invitation/cleaner_invitation.dart';
import '../../../data/models/order/order_offer.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../routes/route_names.dart';

class OrderOffersScreen extends ConsumerStatefulWidget {
  final int orderId;
  final double? orderBudget;
  final String fulfillmentType;


  const OrderOffersScreen({
    super.key,
    required this.orderId,
    this.orderBudget,
    required this.fulfillmentType,
  });

  @override
  ConsumerState<OrderOffersScreen> createState() => _OrderOffersScreenState();
}

class _OrderOffersScreenState extends ConsumerState<OrderOffersScreen> {
  final ResponseRepository _responseRepository = ResponseRepository();
  final InvitationRepository _invitationRepository = InvitationRepository();

  List<OrderOffer> _offers = [];
  bool _isLoading = true;
  int? _selectedOfferId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  // lib/presentation/screens/client/order_offers_screen.dart

  Future<void> _loadOffers() async {
    setState(() => _isLoading = true);
    try {
      List<OrderOffer> offers = [];

      if (widget.fulfillmentType == 'MARKETPLACE') {
        final responses = await _responseRepository.getResponsesForOrder(widget.orderId);
        offers = responses
            .where((r) => r.status == 'PENDING' || r.status == 'ACCEPTED')
            .map((r) => OrderOffer.fromResponse(r))
            .toList();
      } else if (widget.fulfillmentType == 'DIRECT_INVITATION') {
        // ✅ Для клиента используем getMyInvitations()
        final allInvitations = await _invitationRepository.getMyInvitations();
        final invitations = allInvitations.where((inv) => inv.orderId == widget.orderId).toList();
        offers = invitations.map((i) => OrderOffer.fromInvitation(i)).toList();
      }

      setState(() {
        _offers = offers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка загрузки: $e');
      }
    }
  }

  Future<void> _selectCleaner(int offerId) async {
    setState(() => _isProcessing = true);
    try {
      await _responseRepository.selectCleaner(widget.orderId, offerId);
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Клинер выбран!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // lib/presentation/screens/client/order_offers_screen.dart
// Метод _cancelInvitation уже использует правильный вызов:

  Future<void> _cancelInvitation(int invitationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить приглашение'),
        content: const Text('Вы уверены, что хотите отменить приглашение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        // ✅ Теперь этот метод существует
        await _invitationRepository.cancelInvitation(invitationId);
        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Приглашение отменено');
          _loadOffers();
        }
      } catch (e) {
        if (mounted) {
          CustomSnackbar.showError(context, 'Ошибка: $e');
        }
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _viewCleanerProfile(OrderOffer offer) {
    context.push('/profile/${offer.userId}');
  }

  @override
  Widget build(BuildContext context) {
    final isDirectInvitation = widget.fulfillmentType == 'DIRECT_INVITATION';
    final title = isDirectInvitation ? 'Приглашение' : 'Отклики клинеров';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadOffers,
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer()
          : _offers.isEmpty
          ? _buildEmpty(isDirectInvitation)
          : Column(
        children: [
          if (widget.orderBudget != null && !isDirectInvitation)
            _buildBudgetInfo(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _offers.length,
              itemBuilder: (context, index) {
                final offer = _offers[index];
                if (isDirectInvitation) {
                  return _buildInvitationCard(offer);
                } else {
                  return _buildResponseCard(offer);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetInfo() {
    return Container(
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
    );
  }

  // ✅ Карточка для отображения контрпредложения (новой цены)
  Widget _buildCounterOfferBadge(OrderOffer offer) {
    if (!offer.hasCounterOffer) return const SizedBox.shrink();

    final isAboveBudget = widget.orderBudget != null && offer.counterOfferPrice! > widget.orderBudget!;
    final isFromCleaner = offer.isCounterOfferFromCleaner;

    Color getStatusColor() {
      if (offer.isCounterOfferAccepted) return AppColors.success;
      if (offer.isCounterOfferRejected) return Colors.red;
      if (offer.isCounterOfferPending) return AppColors.warning;
      return isAboveBudget ? Colors.orange : Colors.purple;
    }

    String getStatusText() {
      if (offer.isCounterOfferAccepted) return '✓ Принято';
      if (offer.isCounterOfferRejected) return '✗ Отклонено';
      if (offer.isCounterOfferPending) return '⏳ Ожидает ответа';
      return 'Предложено';
    }

    String getSenderLabel() {
      if (isFromCleaner) {
        return '💬 Контрпредложение от клинера';
      } else {
        return '💬 Ваше контрпредложение';
      }
    }

    IconData getSenderIcon() {
      if (isFromCleaner) {
        return Icons.person_outline;
      } else {
        return Icons.check_circle_outline;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isAboveBudget
              ? [Colors.orange.withOpacity(0.1), Colors.red.withOpacity(0.05)]
              : [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: getStatusColor().withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: getStatusColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              offer.isCounterOfferAccepted ? Icons.check_circle :
              offer.isCounterOfferRejected ? Icons.cancel :
              Icons.swap_horiz_rounded,
              size: 20,
              color: getStatusColor(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      getSenderLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: getStatusColor(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        getStatusText(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      getSenderIcon(),
                      size: 14,
                      color: getStatusColor(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${offer.counterOfferPrice!.toInt()} ₸',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAboveBudget ? Colors.orange.shade800 : Colors.purple.shade800,
                      ),
                    ),
                    if (offer.counterOfferSenderName != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'от ${offer.counterOfferSenderName}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (offer.counterOfferMessage != null && offer.counterOfferMessage!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              onPressed: () {
                _showCounterOfferCommentDialog(
                    offer.counterOfferMessage!,
                    offer.counterOfferSenderName ?? 'Клинер'
                );
              },
            ),
        ],
      ),
    );
  }

  void _showCounterOfferCommentDialog(String comment, String senderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.chat_bubble, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Комментарий от $senderName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          comment,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(OrderOffer offer) {
    final isPriceAboveBudget = widget.orderBudget != null && offer.priceOffer > widget.orderBudget!;
    final isAccepted = offer.isAccepted;
    final hasCounterOffer = offer.hasCounterOffer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isAccepted ? AppColors.success.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAccepted
            ? Border.all(color: AppColors.success)
            : (hasCounterOffer ? Border.all(color: Colors.purple.withOpacity(0.3), width: 1.5) : null),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _viewCleanerProfile(offer),
                  child: Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasCounterOffer ? Colors.purple : AppColors.primary,
                            width: hasCounterOffer ? 3 : 2,
                          ),
                          image: offer.cleanerAvatar != null && offer.cleanerAvatar!.isNotEmpty
                              ? DecorationImage(
                            image: NetworkImage(offer.cleanerAvatar!),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: offer.cleanerAvatar == null || offer.cleanerAvatar!.isEmpty
                            ? CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            offer.cleanerName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        )
                            : null,
                      ),
                      if (offer.isVerified)
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
                      if (hasCounterOffer)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.purple,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.swap_horiz, size: 12, color: Colors.white),
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
                              offer.cleanerName,
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
                          if (offer.isVerified)
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
                            offer.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.cleaning_services_rounded, size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.completedOrders} уборок',
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

          // ✅ Отображаем контрпредложение если есть
          if (hasCounterOffer) _buildCounterOfferBadge(offer),

          // Основная цена
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
                        isAccepted ? '✓ Выбранный клинер' : 'Предложенная цена',
                        style: TextStyle(
                          fontSize: 11,
                          color: isAccepted ? AppColors.success : (isPriceAboveBudget ? Colors.red : AppColors.textHint),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${offer.priceOffer.toInt()} ₸',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isAccepted ? AppColors.success : (isPriceAboveBudget ? Colors.red : AppColors.primary),
                            ),
                          ),
                          if (hasCounterOffer) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Есть контрпредложение',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (isPriceAboveBudget && !isAccepted)
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
                if (isAccepted)
                  const Icon(Icons.check_circle, color: AppColors.success, size: 24),
              ],
            ),
          ),

          if (offer.message != null && offer.message!.isNotEmpty) ...[
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
                        offer.message!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (!isAccepted)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _viewCleanerProfile(offer),
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
                      onPressed: _isProcessing ? null : () => _selectCleaner(offer.id),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isProcessing && _selectedOfferId == offer.id
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

  Widget _buildInvitationCard(OrderOffer offer) {
    final isAccepted = offer.isAccepted;
    final isDeclined = offer.isDeclined;
    final isPending = offer.isPending;
    final isExpired = offer.isExpired;
    final hasCounterOffer = offer.hasCounterOffer;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isExpired) {
      statusColor = Colors.grey;
      statusText = 'Истекло';
      statusIcon = Icons.timer_off;
    } else if (isAccepted) {
      statusColor = AppColors.success;
      statusText = 'Принято';
      statusIcon = Icons.check_circle;
    } else if (isDeclined) {
      statusColor = Colors.red;
      statusText = 'Отклонено';
      statusIcon = Icons.cancel;
    } else {
      statusColor = AppColors.warning;
      statusText = 'Ожидает ответа';
      statusIcon = Icons.hourglass_top;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAccepted
            ? Border.all(color: AppColors.success, width: 2)
            : (hasCounterOffer ? Border.all(color: Colors.purple.withOpacity(0.3), width: 1.5) : null),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasCounterOffer ? Colors.purple : AppColors.primary,
                          width: hasCounterOffer ? 3 : 2,
                        ),
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Text(
                          offer.cleanerName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ),
                    if (hasCounterOffer)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.purple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_horiz, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.cleanerName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rate_rounded, size: 16, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            offer.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ✅ Отображаем контрпредложение если есть
          if (hasCounterOffer) _buildCounterOfferBadge(offer),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Статус приглашения',
                        style: TextStyle(fontSize: 11, color: AppColors.textHint),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${offer.priceOffer.toInt()} ₸',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          if (offer.message != null && offer.message!.isNotEmpty) ...[
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
                        offer.message!,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewCleanerProfile(offer),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Посмотреть профиль'),
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : () => _cancelInvitation(offer.id),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Отменить'),
                    ),
                  ),
                ],
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

  Widget _buildEmpty(bool isDirectInvitation) {
    final icon = isDirectInvitation ? Icons.person_add_disabled : Icons.people_outline;
    final title = isDirectInvitation ? 'Нет приглашений' : 'Нет откликов';
    final subtitle = isDirectInvitation
        ? 'Вы еще не отправили приглашение'
        : 'Клинеры еще не откликнулись на ваш заказ';

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
            child: Icon(icon, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
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