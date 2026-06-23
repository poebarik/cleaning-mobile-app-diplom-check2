import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../routes/route_names.dart';
import '../../providers/manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../common/notification_badge_widget.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen> {
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
    final authState = ref.watch(authProvider);
    final user = authState is AuthStateAuthenticated ? authState.user : null;
    final firstName = user?.fullName.split(' ').first ?? 'Менеджер';

    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await ref.read(managerProvider.notifier).loadStats();
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(firstName)),
              if (managerState.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionLabel('Статистика'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildStatsGrid(managerState.stats),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionLabel('Быстрые действия'),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  sliver: SliverToBoxAdapter(
                    child: _buildQuickActions(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────── Header ───────────────────────────────────────────

  Widget _buildHeader(String firstName) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
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
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'M',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добро пожаловать,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              // Notification badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const NotificationBadgeWidget(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Role badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.shield_lefthalf_fill,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Панель менеджера',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Section label ────────────────────────────────────

  Widget _buildSectionLabel(String title) {
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

  // ─────────────────────── Stats grid ───────────────────────────────────────

  Widget _buildStatsGrid(Map<String, dynamic>? stats) {
    final cards = [
      _StatCardData(
        label: 'Ожидают',
        value: '${stats?['pendingOrders'] ?? 0}',
        icon: CupertinoIcons.clock_fill,
        color: const Color(0xFFF39C12),
        bg: const Color(0xFFFFF8E1),
      ),
      _StatCardData(
        label: 'В работе',
        value: '${stats?['inProgressOrders'] ?? 0}',
        icon: CupertinoIcons.arrow_clockwise_circle_fill,
        color: const Color(0xFF0984E3),
        bg: const Color(0xFFE3F2FD),
      ),
      _StatCardData(
        label: 'Выполнено',
        value: '${stats?['completedToday'] ?? 0}',
        icon: CupertinoIcons.checkmark_circle_fill,
        color: const Color(0xFF00B894),
        bg: const Color(0xFFE8F5E9),
      ),
      _StatCardData(
        label: 'Клинеры',
        value: '${stats?['activeCleaners'] ?? 0}',
        icon: CupertinoIcons.person_2_fill,
        color: AppColors.primary,
        bg: const Color(0xFFF0EEFF),
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.55,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _buildStatCard(cards[i]),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: data.color,
                  fontFamily: 'Poppins',
                  height: 1.1,
                ),
              ),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF636E72),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Quick actions ────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
        label: 'Новые заказы',
        icon: CupertinoIcons.doc_text_search,
        color: const Color(0xFF6C5CE7),
        onTap: () => context.push(RouteNames.pendingOrders),
      ),
      _QuickAction(
        label: 'Назначить',
        icon: CupertinoIcons.person_badge_plus_fill,
        color: const Color(0xFF0984E3),
        onTap: () => context.push(RouteNames.pendingOrders),
      ),
      _QuickAction(
        label: 'Клинеры',
        icon: CupertinoIcons.person_2_fill,
        color: const Color(0xFF00B894),
        onTap: () => context.push(RouteNames.cleanersWorkload),
      ),
      _QuickAction(
        label: 'Верификация',
        icon: CupertinoIcons.checkmark_shield_fill,
        color: const Color(0xFFF39C12),
        onTap: () => context.push(RouteNames.pendingVerifications),
      ),
      _QuickAction(
        label: 'Статистика',
        icon: CupertinoIcons.chart_bar_alt_fill,
        color: const Color(0xFFE17055),
        onTap: () => context.push(RouteNames.managerStats),
      ),
      _QuickAction(
        label: 'Уведомления',
        icon: CupertinoIcons.bell_fill,
        color: const Color(0xFF6C5CE7),
        onTap: () => context.push(RouteNames.notifications),
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            _buildActionTile(actions[0]),
            const SizedBox(width: 12),
            _buildActionTile(actions[1]),
            const SizedBox(width: 12),
            _buildActionTile(actions[2]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionTile(actions[3]),
            const SizedBox(width: 12),
            _buildActionTile(actions[4]),
            const SizedBox(width: 12),
            _buildActionTile(actions[5]),
          ],
        ),
      ],
    );
  }

  Widget _buildActionTile(_QuickAction action) {
    return Expanded(
      child: GestureDetector(
        onTap: action.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3436),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Data models ─────────────────────────────────────────────────────────────

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _StatCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}