// lib/presentation/screens/client/all_order_offers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/cleaner_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/response_repository.dart';
import '../../../data/repositories/invitation_repository.dart';
import '../../../data/models/order/order_response.dart';
import '../../../data/models/invitation/cleaner_invitation.dart';
import '../../../data/models/order/order_offer.dart';
import '../../../data/models/order/order.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../routes/route_names.dart';

class AllOrderOffersScreen extends ConsumerStatefulWidget {
  const AllOrderOffersScreen({super.key});

  @override
  ConsumerState<AllOrderOffersScreen> createState() =>
      _AllOrderOffersScreenState();
}

class _AllOrderOffersScreenState extends ConsumerState<AllOrderOffersScreen>
    with SingleTickerProviderStateMixin {
  final OrderRepository _orderRepository = OrderRepository();
  final ResponseRepository _responseRepository = ResponseRepository();
  final InvitationRepository _invitationRepository = InvitationRepository();
  final CleanerRepository _cleanerRepository = CleanerRepository();

  List<OrderOffer> _allOffers = [];
  bool _isLoading = true;
  String _filter = 'ALL';
  final Map<int, int> _userIdCache = {};

  static const _filters = [
    _FilterChip(value: 'ALL', label: 'Все', icon: CupertinoIcons.list_bullet),
    _FilterChip(
        value: 'PENDING',
        label: 'Ожидают',
        icon: CupertinoIcons.clock),
    _FilterChip(
        value: 'ACCEPTED',
        label: 'Принятые',
        icon: CupertinoIcons.checkmark_circle),
    _FilterChip(
        value: 'COUNTER_OFFER',
        label: 'Встречные',
        icon: CupertinoIcons.arrow_2_squarepath),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllOffers();
  }

  Future<int?> _getUserIdByCleanerId(int cleanerId) async {
    if (_userIdCache.containsKey(cleanerId)) {
      final cachedUserId = _userIdCache[cleanerId];
      if (cachedUserId != null && cachedUserId > 0) {
        print('✅ userId найден в кэше: $cachedUserId для cleanerId: $cleanerId');
        return cachedUserId;
      }
    }

    try {
      final userId = await _cleanerRepository.getUserIdByCleanerId(cleanerId);
      if (userId != null && userId > 0) {
        _userIdCache[cleanerId] = userId;
        print('✅ userId получен через API: $userId для cleanerId: $cleanerId');
        return userId;
      }
      print('⚠️ userId не найден для cleanerId: $cleanerId');
      return null;
    } catch (e) {
      print('❌ Ошибка получения userId для cleanerId $cleanerId: $e');
      return null;
    }
  }

  Future<void> _loadAllOffers() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderRepository.getClientOrders();
      List<OrderOffer> allOffers = [];

      for (final order in orders) {
        if (order.status == 'COMPLETED' || order.status == 'CANCELLED') continue;

        try {
          if (order.orderType == 'MARKETPLACE') {
            final responses =
            await _responseRepository.getResponsesForOrder(order.id);
            final offers = responses
                .where((r) => r.status == 'PENDING' || r.status == 'ACCEPTED')
                .map((r) => OrderOffer.fromResponse(r))
                .toList();
            allOffers.addAll(offers);
          }

          if (order.orderType == 'DIRECT_INVITATION' ||
              order.isDirectInvitation == true) {
            final allInvitations =
            await _invitationRepository.getMyInvitations();
            final invitations =
            allInvitations.where((inv) => inv.orderId == order.id).toList();
            final offers =
            invitations.map((i) => OrderOffer.fromInvitation(i)).toList();
            allOffers.addAll(offers);
          }
        } catch (e) {
          print('⚠️ Ошибка загрузки предложений для заказа ${order.id}: $e');
        }
      }

      allOffers.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      List<OrderOffer> filteredOffers = allOffers;
      if (_filter == 'PENDING') {
        filteredOffers = allOffers.where((o) => o.isPending).toList();
      } else if (_filter == 'ACCEPTED') {
        filteredOffers = allOffers.where((o) => o.isAccepted).toList();
      } else if (_filter == 'COUNTER_OFFER') {
        filteredOffers = allOffers.where((o) => o.hasCounterOffer).toList();
      }

      setState(() {
        _allOffers = filteredOffers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка загрузки: $e');
      }
    }
  }

  Future<void> _selectCleaner(int orderId, int responseId) async {
    setState(() => _isLoading = true);
    try {
      await _responseRepository.selectCleaner(orderId, responseId);
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Клинер выбран!');
        _loadAllOffers();
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _viewCleanerProfile(OrderOffer offer) async {
    if (offer == null) {
      CustomSnackbar.showError(context, 'Информация о клинере недоступна');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await _getUserIdByCleanerId(offer.cleanerId);

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📸 ПЕРЕХОД В ПРОФИЛЬ:');
      print('  - cleanerId: ${offer.cleanerId}');
      print('  - cleanerName: ${offer.cleanerName}');
      print('  - полученный userId: $userId');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (userId != null && userId > 0) {
        context.push('/profile/$userId');
      } else {
        CustomSnackbar.showError(context, 'Информация о клинере недоступна');
      }
    } catch (e) {
      print('❌ Ошибка перехода в профиль: $e');
      CustomSnackbar.showError(context, 'Ошибка загрузки профиля');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptCounterOffer(OrderOffer offer) async {
    if (offer.invitationId == null) {
      CustomSnackbar.showError(context, 'Ошибка: ID приглашения не найден');
      return;
    }
    final confirmed = await _showConfirmDialog(
      title: 'Принять цену',
      content:
      'Вы соглашаетесь на цену ${offer.counterOfferPrice?.toInt() ?? 0} ₸?',
      confirmLabel: 'Принять',
      confirmColor: const Color(0xFF00CEC9),
    );
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _invitationRepository.acceptPrice(offer.invitationId!);
        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Цена принята!');
          _loadAllOffers();
        }
      } catch (e) {
        if (mounted) CustomSnackbar.showError(context, 'Ошибка: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectCounterOffer(OrderOffer offer) async {
    if (offer.invitationId == null) {
      CustomSnackbar.showError(context, 'Ошибка: ID приглашения не найден');
      return;
    }
    final confirmed = await _showConfirmDialog(
      title: 'Отклонить цену',
      content:
      'Вы отклоняете цену ${offer.counterOfferPrice?.toInt() ?? 0} ₸?',
      confirmLabel: 'Отклонить',
      confirmColor: const Color(0xFFFF6B6B),
    );
    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _invitationRepository.rejectPrice(offer.invitationId!);
        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Цена отклонена');
          _loadAllOffers();
        }
      } catch (e) {
        if (mounted) CustomSnackbar.showError(context, 'Ошибка: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Отмена',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: Column(
        children: [
          // ✅ Header - НЕ СТИКИ
          _buildHeader(),

          // ✅ Фильтры - НЕ СТИКИ (скроллится вместе с контентом)
          _buildFilterBar(),

          // ✅ Контент
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _allOffers.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
              onRefresh: _loadAllOffers,
              color: const Color(0xFF6C5CE7),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _allOffers.length,
                itemBuilder: (context, index) =>
                    _buildOfferCard(_allOffers[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Новый виджет хедера (без SliverAppBar)
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF8B7FF0),
            Color(0xFFA29BFE)
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Предложения',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    'Отклики и приглашения клинеров',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _loadAllOffers,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Новый виджет фильтров (не стики)
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: _filters.length,
        itemBuilder: (ctx, i) {
          final chip = _filters[i];
          final isSelected = _filter == chip.value;
          return GestureDetector(
            onTap: () {
              setState(() => _filter = chip.value);
              _loadAllOffers();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                )
                    : null,
                color: isSelected ? null : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.grey.shade200,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    chip.icon,
                    size: 13,
                    color: isSelected
                        ? Colors.white
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    chip.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : Colors.grey.shade600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOfferCard(OrderOffer offer) {
    final isAccepted = offer.isAccepted;
    final hasCounterOffer = offer.hasCounterOffer;
    final isPending = offer.isPending;
    final isCounterOfferPending = offer.isCounterOfferPending;
    final isInvitation = offer.type == 'invitation';

    Color accentColor = const Color(0xFF6C5CE7);
    if (isAccepted) accentColor = const Color(0xFF00CEC9);
    if (hasCounterOffer) accentColor = const Color(0xFFAA6FEA);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isAccepted
            ? Border.all(color: const Color(0xFF00CEC9).withOpacity(0.5), width: 1.5)
            : hasCounterOffer
            ? Border.all(
            color: const Color(0xFFAA6FEA).withOpacity(0.4), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Шапка карточки ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                // Аватар
                GestureDetector(
                  onTap: () => _viewCleanerProfile(offer),
                  child: Stack(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              accentColor,
                              accentColor.withOpacity(0.6)
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          image: offer.cleanerAvatar != null &&
                              offer.cleanerAvatar!.isNotEmpty
                              ? DecorationImage(
                            image:
                            NetworkImage(offer.cleanerAvatar!),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: offer.cleanerAvatar == null ||
                            offer.cleanerAvatar!.isEmpty
                            ? Center(
                          child: Text(
                            offer.cleanerName.isNotEmpty
                                ? offer.cleanerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        )
                            : null,
                      ),
                      if (hasCounterOffer)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFAA6FEA),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33AA6FEA),
                                  blurRadius: 4,
                                )
                              ],
                            ),
                            child: const Icon(
                              Icons.swap_horiz_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      if (isAccepted)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00CEC9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
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
                                color: Color(0xFF2D3436),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isInvitation
                                  ? const Color(0xFF0984E3).withOpacity(0.1)
                                  : const Color(0xFF00B894).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isInvitation ? 'Приглашение' : 'Отклик',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isInvitation
                                    ? const Color(0xFF0984E3)
                                    : const Color(0xFF00B894),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rate_rounded,
                            size: 15,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            offer.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.cleaning_services_rounded,
                            size: 13,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${offer.completedOrders} уборок',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Цена ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentColor.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentColor, accentColor.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isAccepted
                              ? Icons.check_circle_rounded
                              : Icons.monetization_on_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAccepted
                                  ? 'Принято'
                                  : isPending
                                  ? 'Ожидает ответа'
                                  : 'Предложено',
                              style: TextStyle(
                                fontSize: 11,
                                color: accentColor.withOpacity(0.7),
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${offer.priceOffer.toInt()} ₸',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Контрпредложение ────────────────────────────────
                if (hasCounterOffer) ...[
                  const SizedBox(height: 10),
                  _buildCounterOfferBadge(offer),
                ],

                // ── Сообщение ──────────────────────────────────────
                if (offer.message != null && offer.message!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.chat_bubble_text,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            offer.message!,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade600,
                              fontFamily: 'Poppins',
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Кнопки ────────────────────────────────────────
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _viewCleanerProfile(offer),
                        icon: const Icon(CupertinoIcons.person, size: 14),
                        label: const Text('Профиль'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6C5CE7),
                          side: const BorderSide(
                            color: Color(0xFF6C5CE7),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    if (isPending && offer.type == 'response') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6C5CE7),
                                Color(0xFFA29BFE)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6C5CE7)
                                    .withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _selectCleaner(offer.orderId, offer.id),
                            icon: const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white),
                            label: const Text(
                              'Выбрать',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // ── Кнопки контрпредложения ──────────────────────
                if (hasCounterOffer && isCounterOfferPending) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptCounterOffer(offer),
                          icon: const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white),
                          label: const Text(
                            'Принять цену',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00CEC9),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rejectCounterOffer(offer),
                          icon: const Icon(Icons.close_rounded,
                              size: 14, color: Colors.white),
                          label: const Text(
                            'Отклонить',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterOfferBadge(OrderOffer offer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFAA6FEA).withOpacity(0.1),
            const Color(0xFF6C5CE7).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFAA6FEA).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFAA6FEA).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              size: 16,
              color: Color(0xFFAA6FEA),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Встречное предложение',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFAA6FEA),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '${offer.counterOfferPrice?.toInt() ?? 0} ₸',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6C5CE7),
                    fontFamily: 'Poppins',
                  ),
                ),
                if (offer.counterOfferSenderName != null)
                  Text(
                    'от ${offer.counterOfferSenderName}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
          if (offer.counterOfferMessage != null &&
              offer.counterOfferMessage!.isNotEmpty)
            GestureDetector(
              onTap: () => _showCounterOfferComment(
                offer.counterOfferMessage!,
                offer.counterOfferSenderName ?? 'Клинер',
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFAA6FEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.chat_bubble_text,
                  size: 16,
                  color: Color(0xFFAA6FEA),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showCounterOfferComment(String comment, String senderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.chat_bubble_rounded,
              color: Color(0xFF6C5CE7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Комментарий от $senderName',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          comment,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            height: 1.5,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Закрыть',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
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
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _shimmerBox(58, 58, radius: 29),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _shimmerBox(14, 150),
                        const SizedBox(height: 8),
                        _shimmerBox(10, 100),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _shimmerBox(60, double.infinity, radius: 14),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _shimmerBox(40, double.infinity, radius: 12)),
                  const SizedBox(width: 10),
                  Expanded(child: _shimmerBox(40, double.infinity, radius: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double height, double width, {double radius = 8}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDE9FE), Color(0xFFC4B5FD)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('📩', style: TextStyle(fontSize: 50)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Нет предложений',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'У вас пока нет активных предложений\nот клинеров',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loadAllOffers,
              icon: const Icon(CupertinoIcons.refresh,
                  size: 16, color: Colors.white),
              label: const Text(
                'Обновить',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C5CE7),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip {
  final String value;
  final String label;
  final IconData icon;
  const _FilterChip({
    required this.value,
    required this.label,
    required this.icon,
  });
}