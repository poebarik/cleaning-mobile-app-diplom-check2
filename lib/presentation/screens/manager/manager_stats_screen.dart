import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/manager_provider.dart';

class ManagerStatsScreen extends ConsumerStatefulWidget {
  const ManagerStatsScreen({super.key});

  @override
  ConsumerState<ManagerStatsScreen> createState() => _ManagerStatsScreenState();
}

class _ManagerStatsScreenState extends ConsumerState<ManagerStatsScreen> {
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
        title: const Text('Статистика'),
        elevation: 0,
      ),
      body: managerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : managerState.stats == null
          ? const Center(child: Text('Нет данных'))
          : GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildStatCard('Всего заказов', managerState.stats!['totalOrders'] ?? 0, Icons.shopping_bag, Colors.blue),
          _buildStatCard('Завершено', managerState.stats!['completedOrders'] ?? 0, Icons.check_circle, Colors.green),
          _buildStatCard('Активных клинеров', managerState.stats!['activeCleaners'] ?? 0, Icons.cleaning_services, Colors.orange),
          _buildStatCard('Средний рейтинг', managerState.stats!['avgRating']?.toStringAsFixed(1) ?? '0', Icons.star, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, dynamic value, IconData icon, Color color) {
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