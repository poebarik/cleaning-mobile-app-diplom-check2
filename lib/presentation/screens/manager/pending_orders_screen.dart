import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/route_names.dart';
import '../../providers/manager_provider.dart';

class PendingOrdersScreen extends ConsumerStatefulWidget {
  const PendingOrdersScreen({super.key});

  @override
  ConsumerState<PendingOrdersScreen> createState() =>
      _PendingOrdersScreenState();
}

class _PendingOrdersScreenState extends ConsumerState<PendingOrdersScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(managerProvider.notifier).loadPendingOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);
    final orders = managerState.pendingOrders ?? [];
    final filtered = _searchQuery.isEmpty
        ? orders
        : orders.where((o) {
            final id = '${o['id']}'.toLowerCase();
            final addr = (o['address'] ?? '').toLowerCase();
            final client = (o['clientName'] ?? '').toLowerCase();
            final q = _searchQuery.toLowerCase();
            return id.contains(q) || addr.contains(q) || client.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, orders.length),
            _buildSearchBar(),
            if (!managerState.isLoading && orders.isNotEmpty)
              _buildStatusBar(filtered.length, orders.length),
            Expanded(
              child: managerState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : orders.isEmpty
                      ? _buildEmptyState()
                      : filtered.isEmpty
                          ? _buildNoResults()
                          : RefreshIndicator(
                              color: AppColors.primary,
                              onRefresh: () async {
                                await ref
                                    .read(managerProvider.notifier)
                                    .loadPendingOrders();
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    20, 4, 20, 20),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildOrderCard(context, filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Header ───────────────────────────────────────────

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF0984E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x406C5CE7),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ожидающие заказы',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Всего: $count заказов',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                ref.read(managerProvider.notifier).loadPendingOrders(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(CupertinoIcons.refresh,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Search ───────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Поиск по заказам...',
          hintStyle: const TextStyle(
              color: AppColors.textHint, fontFamily: 'Poppins'),
          prefixIcon: const Icon(CupertinoIcons.search,
              color: AppColors.textHint, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(CupertinoIcons.clear_circled_solid,
                      color: AppColors.textHint, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
    );
  }

  // ─────────────────────── Status bar ───────────────────────────────────────

  Widget _buildStatusBar(int filtered, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _searchQuery.isEmpty
                  ? '$total заказов'
                  : 'Найдено: $filtered из $total',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Order card ───────────────────────────────────────

  Widget _buildOrderCard(
      BuildContext context, Map<String, dynamic> order) {
    final status = order['status'] ?? 'PENDING';
    final (statusBg, statusText, statusLabel) = _getStatusStyle(status);

    return Container(
      margin: const EdgeInsets.only(top: 12),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF6C5CE7), Color(0xFF0984E3)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(CupertinoIcons.doc_text_fill,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Заказ #${order['id']}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Color(0xFF2D3436),
                        ),
                      ),
                      if (order['service'] != null)
                        Text(
                          '${order['service']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusText,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(height: 1, color: const Color(0xFFF1F0FF)),
          // Info rows
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow(
                  CupertinoIcons.location_solid,
                  order['address'] ?? 'Адрес не указан',
                  const Color(0xFF6C5CE7),
                ),
                const SizedBox(height: 8),
                _infoRow(
                  CupertinoIcons.person_fill,
                  order['clientName'] ?? 'Клиент',
                  const Color(0xFF0984E3),
                ),
                if (order['scheduledDate'] != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    CupertinoIcons.calendar,
                    order['scheduledDate'].toString(),
                    const Color(0xFF00B894),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push(
                          '${RouteNames.assignCleaner}/${order['id']}');
                    },
                    icon: const Icon(CupertinoIcons.person_badge_plus,
                        size: 18),
                    label: const Text('Назначить клинера'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      textStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2D3436),
              fontFamily: 'Poppins',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─────────────────────── Empty / no results ───────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.tray,
                size: 42, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет ожидающих заказов',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Все заказы обработаны',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.search,
                size: 36, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ничего не найдено',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Status helpers ───────────────────────────────────

  (Color, Color, String) _getStatusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return (const Color(0xFFFFF8E1), const Color(0xFFF57F17), 'Ожидает');
      case 'IN_PROGRESS':
        return (const Color(0xFFE3F2FD), const Color(0xFF1565C0), 'В работе');
      case 'COMPLETED':
        return (const Color(0xFFE8F5E9), const Color(0xFF2E7D32), 'Завершён');
      case 'CANCELLED':
        return (const Color(0xFFFFEBEE), const Color(0xFFC62828), 'Отменён');
      default:
        return (const Color(0xFFF0EEFF), AppColors.primary, status);
    }
  }
}