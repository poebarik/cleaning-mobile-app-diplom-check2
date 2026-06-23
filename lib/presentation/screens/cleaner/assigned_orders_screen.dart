// lib/presentation/screens/cleaner/assigned_orders_screen.dart
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

class AssignedOrdersScreen extends ConsumerStatefulWidget {
  const AssignedOrdersScreen({super.key});

  @override
  ConsumerState<AssignedOrdersScreen> createState() => _AssignedOrdersScreenState();
}

class _AssignedOrdersScreenState extends ConsumerState<AssignedOrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final repository = OrderRepository();
      final orders = await repository.getCleanerOrders();

      List<Order> filteredOrders = orders;
      if (_filter == 'ACTIVE') {
        filteredOrders = orders.where((o) =>
        o.status != 'COMPLETED' && o.status != 'CANCELLED'
        ).toList();
      } else if (_filter == 'COMPLETED') {
        filteredOrders = orders.where((o) =>
        o.status == 'COMPLETED' || o.status == 'CANCELLED'
        ).toList();
      }

      setState(() {
        _orders = filteredOrders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) CustomSnackbar.showError(context, 'Ошибка: $e');
    }
  }

  Future<void> _updateStatus(int orderId, OrderAction action, String label, {Map<String, dynamic>? payload}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Text('Подтвердить действие "$label"?', style: const TextStyle(fontFamily: 'Poppins')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Подтвердить', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await OrderRepository().executeAction(orderId, action, payload ?? {});
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Статус обновлён');
        _loadOrders();
      }
    } catch (e) {
      if (mounted) CustomSnackbar.showError(context, 'Ошибка: $e');
    }
  }

  Future<void> _showCancelDialog(int orderId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Отмена заказа', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите причину отмены:', style: TextStyle(fontFamily: 'Poppins')),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Причина отмены',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Отменить', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _updateStatus(
        orderId,
        OrderAction.cancel,
        'Отмена заказа',
        payload: {'reason': reasonController.text.isNotEmpty ? reasonController.text : 'Не указана'},
      );
    }
  }

  void _navigateToProfile(int? userId) {
    // Для отладки
    print('🔍 Navigating to profile with userId: $userId');

    if (userId == null || userId == 0) {
      CustomSnackbar.showError(context, 'Информация о клиенте недоступна');
      return;
    }
    context.push('/profile/$userId');
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String? name) {
    if (name == null || name.isEmpty) return AppColors.primary;
    final colors = [
      Colors.blue.shade300,
      Colors.green.shade300,
      Colors.orange.shade300,
      Colors.purple.shade300,
      Colors.pink.shade300,
      Colors.teal.shade300,
      Colors.indigo.shade300,
      Colors.red.shade300,
    ];
    final index = name.length % colors.length;
    return colors[index];
  }

  Widget _buildAvatar(String? avatarUrl, String? name, {double size = 48}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImage(
          imageUrl: avatarUrl,
          placeholder: (context, url) => Container(
            color: _getAvatarColor(name),
            child: Center(
              child: Text(
                _getInitials(name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: _getAvatarColor(name),
            child: Center(
              child: Text(
                _getInitials(name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          fit: BoxFit.cover,
        )
            : Container(
          color: _getAvatarColor(name),
          child: Center(
            child: Text(
              _getInitials(name),
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Новый метод для отображения фото заказа
  Widget _buildOrderImages(List<String>? imageUrls) {
    if (imageUrls == null || imageUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length > 5 ? 5 : imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = imageUrls[index];
          // ✅ Формируем полный URL
          final fullUrl = imageUrl.startsWith('http')
              ? imageUrl
              : 'http://localhost:8080/api/files/$imageUrl';

          return Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: fullUrl,
                fit: BoxFit.cover,
                placeholder: (context, _) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, _, __) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 30,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EFF8),
        elevation: 0,
        title: const Text(
          'Мои заказы',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: Color(0xFF2D3436),
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.arrow_2_circlepath, color: Color(0xFF6C5CE7)),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? _buildShimmer()
                : _orders.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        color: const Color(0xFF6C5CE7),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          itemCount: _orders.length,
                          itemBuilder: (ctx, i) => _buildOrderCard(_orders[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      {'value': 'ALL', 'label': 'Все'},
      {'value': 'ACTIVE', 'label': 'Активные'},
      {'value': 'COMPLETED', 'label': 'Завершенные'},
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filter == filter['value'];
          return GestureDetector(
            onTap: () {
              setState(() => _filter = filter['value']!);
              _loadOrders();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: const Color(0xFF6C5CE7).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
                border: Border.all(
                  color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  filter['label']!,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12,
                    color: isSelected ? Colors.white : const Color(0xFF636E72),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final actions = _getAvailableActions(order.status);
    final userId = order.userId ?? order.clientId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('${RouteNames.jobDetails}/${order.id}'),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToProfile(userId),
                        child: _buildAvatar(order.clientAvatarUrl, order.clientName),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _navigateToProfile(userId),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      order.clientName,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFF2D3436),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 14,
                                    color: Color(0xFFB2BEC3),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Заказ №${order.id} • ${order.serviceName}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xFF636E72),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F2F6)),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Icon(CupertinoIcons.location, size: 14, color: Color(0xFFB2BEC3)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.address,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Color(0xFF636E72),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(CupertinoIcons.calendar, size: 14, color: Color(0xFFB2BEC3)),
                      const SizedBox(width: 6),
                      Text(
                        '${order.orderDate.day}.${order.orderDate.month}.${order.orderDate.year}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFF636E72),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF8B7FF0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '${order.budget?.toInt() ?? 0} ₸',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (order.imageObjectNames != null && order.imageObjectNames!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildOrderImages(order.imageObjectNames),
                  ],

                  if (order.description != null && order.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.doc_text, size: 15, color: Color(0xFFB2BEC3)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.description!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF636E72),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: actions.map((action) => _buildActionButton(order.id, action)).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(int orderId, Map<String, dynamic> action) {
    final color = action['color'] as Color;
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 56) / 2 - 4,
      child: GestureDetector(
        onTap: () {
          if (action['action'] == OrderAction.cancel) {
            _showCancelDialog(orderId);
          } else {
            _updateStatus(orderId, action['action'], action['label']);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.15),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action['icon'], size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                action['label'],
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final info = _getStatusInfo(status);
    final color = info['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            info['label'],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableActions(String status) {
    final actions = <Map<String, dynamic>>[];

    switch (status) {
      case 'ASSIGNED':
      case 'ACCEPTED':
        actions.add({
          'action': OrderAction.start,
          'label': 'Начать',
          'icon': CupertinoIcons.play_fill,
          'color': const Color(0xFF6C5CE7),
        });
        actions.add({
          'action': OrderAction.cancel,
          'label': 'Отменить',
          'icon': CupertinoIcons.xmark_circle_fill,
          'color': const Color(0xFFEB3B5A),
        });
        break;

      case 'IN_PROGRESS':
        actions.add({
          'action': OrderAction.complete,
          'label': 'Завершить',
          'icon': CupertinoIcons.checkmark_seal_fill,
          'color': const Color(0xFF20BF6B),
        });
        actions.add({
          'action': OrderAction.cancel,
          'label': 'Отменить',
          'icon': CupertinoIcons.xmark_circle_fill,
          'color': const Color(0xFFEB3B5A),
        });
        break;

      case 'PENDING':
        actions.add({
          'action': OrderAction.acceptInvitation,
          'label': 'Принять',
          'icon': CupertinoIcons.checkmark_alt_circle_fill,
          'color': const Color(0xFF20BF6B),
        });
        actions.add({
          'action': OrderAction.declineInvitation,
          'label': 'Отклонить',
          'icon': CupertinoIcons.xmark_circle_fill,
          'color': const Color(0xFFEB3B5A),
        });
        actions.add({
          'action': OrderAction.counterOffer,
          'label': 'Предложить цену',
          'icon': CupertinoIcons.money_rubl_circle,
          'color': const Color(0xFFFFA94D),
        });
        break;
    }

    return actions;
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'PENDING':
        return {'label': 'Ожидает', 'color': const Color(0xFFFFA94D)};
      case 'ASSIGNED':
        return {'label': 'Назначен', 'color': const Color(0xFF0984E3)};
      case 'ACCEPTED':
        return {'label': 'Принят', 'color': const Color(0xFF0984E3)};
      case 'IN_PROGRESS':
        return {'label': 'В работе', 'color': const Color(0xFF6C5CE7)};
      case 'COMPLETED':
        return {'label': 'Завершен', 'color': const Color(0xFF20BF6B)};
      case 'CANCELLED':
        return {'label': 'Отменен', 'color': const Color(0xFFEB3B5A)};
      default:
        return {'label': status, 'color': Colors.grey};
    }
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F2F6)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 14, width: 120, color: const Color(0xFFF1F2F6)),
                      const SizedBox(height: 6),
                      Container(height: 10, width: 80, color: const Color(0xFFF1F2F6)),
                    ],
                  ),
                ),
                Container(width: 60, height: 24, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFFF1F2F6))),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0xFFF1F2F6)),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(width: 16, height: 16, color: const Color(0xFFF1F2F6)),
                const SizedBox(width: 8),
                Container(height: 12, width: 140, color: const Color(0xFFF1F2F6)),
                const Spacer(),
                Container(width: 70, height: 24, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFFF1F2F6))),
              ],
            ),
          ],
        ),
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
              color: const Color(0xFF6C5CE7).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.briefcase,
              size: 48,
              color: Color(0xFF6C5CE7),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет назначенных заказов',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Откликнитесь на доступные заказы',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF636E72),
            ),
          ),
        ],
      ),
    );
  }
}
