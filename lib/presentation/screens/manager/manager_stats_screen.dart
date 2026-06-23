import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/manager_provider.dart';

class ManagerStatsScreen extends ConsumerStatefulWidget {
  const ManagerStatsScreen({super.key});

  @override
  ConsumerState<ManagerStatsScreen> createState() =>
      _ManagerStatsScreenState();
}

class _ManagerStatsScreenState extends ConsumerState<ManagerStatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) ref.read(managerProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: managerState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : managerState.stats == null
                      ? _buildNoData()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: () async {
                            await ref
                                .read(managerProvider.notifier)
                                .loadStats();
                          },
                          child: _buildContent(managerState.stats!),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Header ───────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE17055), Color(0xFFFD79A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40E17055),
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
                  'Статистика',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Обзор показателей',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => ref.read(managerProvider.notifier).loadStats(),
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

  // ─────────────────────── Content ──────────────────────────────────────────

  Widget _buildContent(Map<String, dynamic> stats) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        _sectionTitle('Заказы'),
        const SizedBox(height: 12),
        _buildStatsGrid([
          _StatItem(
            label: 'Всего заказов',
            value: '${stats['totalOrders'] ?? 0}',
            icon: CupertinoIcons.doc_text_fill,
            color: AppColors.primary,
            bg: const Color(0xFFF0EEFF),
          ),
          _StatItem(
            label: 'Завершено',
            value: '${stats['completedOrders'] ?? 0}',
            icon: CupertinoIcons.checkmark_circle_fill,
            color: const Color(0xFF00B894),
            bg: const Color(0xFFE8F5E9),
          ),
          _StatItem(
            label: 'В процессе',
            value: '${stats['inProgressOrders'] ?? 0}',
            icon: CupertinoIcons.arrow_clockwise_circle_fill,
            color: const Color(0xFF0984E3),
            bg: const Color(0xFFE3F2FD),
          ),
          _StatItem(
            label: 'Отменено',
            value: '${stats['cancelledOrders'] ?? 0}',
            icon: CupertinoIcons.xmark_circle_fill,
            color: const Color(0xFFD63031),
            bg: const Color(0xFFFFEBEE),
          ),
        ]),
        const SizedBox(height: 28),
        _sectionTitle('Клинеры'),
        const SizedBox(height: 12),
        _buildStatsGrid([
          _StatItem(
            label: 'Активных',
            value: '${stats['activeCleaners'] ?? 0}',
            icon: CupertinoIcons.person_2_fill,
            color: const Color(0xFF00B894),
            bg: const Color(0xFFE8F5E9),
          ),
          _StatItem(
            label: 'Всего',
            value: '${stats['totalCleaners'] ?? 0}',
            icon: CupertinoIcons.person_3_fill,
            color: AppColors.primary,
            bg: const Color(0xFFF0EEFF),
          ),
          _StatItem(
            label: 'Рейтинг',
            value: (stats['avgRating'] != null)
                ? '${(stats['avgRating'] as num).toStringAsFixed(1)} ★'
                : '—',
            icon: CupertinoIcons.star_fill,
            color: const Color(0xFFF39C12),
            bg: const Color(0xFFFFF8E1),
          ),
          _StatItem(
            label: 'Верификаций',
            value: '${stats['pendingVerifications'] ?? 0}',
            icon: CupertinoIcons.checkmark_shield_fill,
            color: const Color(0xFFE17055),
            bg: const Color(0xFFFFF0EE),
          ),
        ]),
        const SizedBox(height: 28),
        _sectionTitle('Финансы'),
        const SizedBox(height: 12),
        _buildFinanceCard(stats),
      ],
    );
  }

  Widget _buildStatsGrid(List<_StatItem> items) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _buildStatCard(items[i]),
    );
  }

  Widget _buildStatCard(_StatItem item) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.bg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: item.color,
                  fontFamily: 'Poppins',
                  height: 1.1,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(Map<String, dynamic> stats) {
    final revenue = stats['totalRevenue'] ?? stats['revenue'] ?? 0;
    final avgOrder = stats['avgOrderValue'] ?? stats['averageOrderValue'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF0984E3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(CupertinoIcons.money_dollar_circle_fill,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Финансовые показатели',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _financeItem(
                    'Общая выручка', '$revenue ₽', CupertinoIcons.chart_bar_fill),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: _financeItem(
                    'Средний чек', '$avgOrder ₽', CupertinoIcons.tag_fill),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _financeItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 11,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF2D3436),
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFE17055).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.chart_bar_alt_fill,
                size: 42, color: Color(0xFFE17055)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет данных',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
}