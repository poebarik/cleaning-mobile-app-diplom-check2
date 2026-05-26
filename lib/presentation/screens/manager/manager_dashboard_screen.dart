import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/route_names.dart';
import '../../providers/manager_provider.dart';
import '../../providers/notification_provider.dart';
import '../common/notification_badge_widget.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(managerProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель менеджера'),
        actions: const [
          NotificationBadgeWidget(),
        ],
      ),
      body: managerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildStatsGrid(managerState.stats),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(RouteNames.pendingOrders);
        },
        child: const Icon(Icons.assignment),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Дашборд',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending_actions_outlined),
            label: 'Заказы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Клинеры',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Статистика',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? stats) {
    if (stats == null) return const SizedBox.shrink();

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard('Pending Orders', stats['pendingOrders'] ?? 0, Icons.pending, Colors.orange),
        _buildStatCard('In Progress', stats['inProgressOrders'] ?? 0, Icons.play_circle, Colors.blue),
        _buildStatCard('Completed Today', stats['completedToday'] ?? 0, Icons.check_circle, Colors.green),
        _buildStatCard('Active Cleaners', stats['activeCleaners'] ?? 0, Icons.cleaning_services, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}