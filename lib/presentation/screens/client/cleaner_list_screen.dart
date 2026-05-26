import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../../routes/route_names.dart';
import '../../providers/cleaner_provider.dart';
import '../../../data/models/cleaner/cleaner.dart';

class CleanerListScreen extends ConsumerStatefulWidget {
  final int? orderId;
  const CleanerListScreen({super.key, this.orderId});

  @override
  ConsumerState<CleanerListScreen> createState() => _CleanerListScreenState();
}

class _CleanerListScreenState extends ConsumerState<CleanerListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cleanerProvider.notifier).loadCleaners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cleanerState = ref.watch(cleanerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Выберите клинера'),
        elevation: 0,
      ),
      body: cleanerState.isLoading
          ? const ShimmerLoading(child: SizedBox(height: 120))
          : cleanerState.isError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: ${cleanerState.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(cleanerProvider.notifier).loadCleaners();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      )
          : cleanerState.cleaners == null || cleanerState.cleaners!.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Нет доступных клинеров',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: cleanerState.cleaners!.length,
        itemBuilder: (context, index) {
          final cleaner = cleanerState.cleaners![index];
          return _buildCleanerCard(cleaner);
        },
      ),
    );
  }

  Widget _buildCleanerCard(Cleaner cleaner) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // Передаем cleanerId в следующий экран
          context.push(
            '${RouteNames.cleanerDetails}/${cleaner.id}',
            extra: {'orderId': widget.orderId},
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade200,
                child: Text(
                  cleaner.fullName.isNotEmpty ? cleaner.fullName[0] : '?',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleaner.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          cleaner.rating?.toStringAsFixed(1) ?? 'Нет оценок',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.cleaning_services, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${cleaner.completedOrders ?? 0} заказов',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    if (cleaner.pricePerHour != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${cleaner.pricePerHour} ₽/час',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}