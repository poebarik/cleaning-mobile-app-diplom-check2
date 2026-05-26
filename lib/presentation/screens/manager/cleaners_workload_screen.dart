import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/manager_provider.dart';

class CleanersWorkloadScreen extends ConsumerStatefulWidget {
  const CleanersWorkloadScreen({super.key});

  @override
  ConsumerState<CleanersWorkloadScreen> createState() => _CleanersWorkloadScreenState();
}

class _CleanersWorkloadScreenState extends ConsumerState<CleanersWorkloadScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(managerProvider.notifier).loadAvailableCleaners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Занятость клинеров'),
        elevation: 0,
      ),
      body: managerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : managerState.cleaners == null || managerState.cleaners!.isEmpty
          ? const Center(child: Text('Нет данных о клинерах'))
          : ListView.builder(
        itemCount: managerState.cleaners!.length,
        itemBuilder: (context, index) {
          final cleaner = managerState.cleaners![index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(cleaner['fullName'][0]),
              ),
              title: Text(cleaner['fullName']),
              subtitle: Text('${cleaner['activeOrders'] ?? 0} активных заказов'),
              trailing: Text('${cleaner['pricePerHour']} ₽/час'),
            ),
          );
        },
      ),
    );
  }
}