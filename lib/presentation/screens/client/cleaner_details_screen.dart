import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../providers/cleaner_provider.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../data/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../routes/route_names.dart';

class CleanerDetailsScreen extends ConsumerStatefulWidget {
  final int cleanerId;
  const CleanerDetailsScreen({super.key, required this.cleanerId});

  @override
  ConsumerState<CleanerDetailsScreen> createState() => _CleanerDetailsScreenState();
}

class _CleanerDetailsScreenState extends ConsumerState<CleanerDetailsScreen> {
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    // Добавляем задержку для загрузки деталей
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cleanerProvider.notifier).loadCleanerDetails(widget.cleanerId);
    });
  }

  Future<void> _selectCleaner() async {
    setState(() {
      _isSelecting = true;
    });

    try {
      // Получаем orderId из extra параметров
      final orderId = ModalRoute.of(context)?.settings.arguments as int?;

      if (orderId == null) {
        CustomSnackbar.showError(context, 'Не удалось определить заказ');
        return;
      }

      final dio = DioClient.instance;
      final response = await dio.patch(
        '${ApiConstants.baseUrl}${ApiConstants.orders}/$orderId/assign',
        data: {'cleanerId': widget.cleanerId},
      );

      if (response.statusCode == 200) {
        if (context.mounted) {
          CustomSnackbar.showSuccess(context, 'Клинер назначен на заказ');
          context.go(RouteNames.myOrders);
        }
      } else {
        throw Exception('Ошибка назначения клинера');
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackbar.showError(context, 'Ошибка: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSelecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cleanerState = ref.watch(cleanerProvider);
    final cleaner = cleanerState.cleaner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль клинера'),
        elevation: 0,
      ),
      body: cleanerState.isLoading
          ? const Center(child: CircularProgressIndicator())
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
                ref.read(cleanerProvider.notifier).loadCleanerDetails(widget.cleanerId);
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      )
          : cleaner == null
          ? const Center(child: Text('Клинер не найден'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and basic info
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(60),
                    child: cleaner.avatar != null && cleaner.avatar!.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: cleaner.avatar!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, size: 60),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.person, size: 60),
                      ),
                    )
                        : Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, size: 60),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    cleaner.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        cleaner.rating?.toStringAsFixed(1) ?? 'Нет оценок',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.cleaning_services, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${cleaner.completedOrders ?? 0} заказов',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  if (cleaner.isAvailable != null)
                    const SizedBox(height: 8),
                  if (cleaner.isAvailable != null)
                    Center(
                      child: StatusChip(
                        status: cleaner.isAvailable! ? 'OPEN' : 'CANCELLED',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Price
            if (cleaner.pricePerHour != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Стоимость часа',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${cleaner.pricePerHour} ₽/час',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Bio
            if (cleaner.bio != null && cleaner.bio!.isNotEmpty) ...[
              const Text(
                'О себе',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cleaner.bio!,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
            ],
            // Services
            if (cleaner.services != null && cleaner.services!.isNotEmpty) ...[
              const Text(
                'Услуги',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cleaner.services!.map((service) {
                  return Chip(
                    label: Text(service),
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 24),
            // Select button
            CustomButton(
              onPressed: _selectCleaner,
              text: 'Выбрать этого клинера',
              isLoading: _isSelecting,
            ),
          ],
        ),
      ),
    );
  }
}