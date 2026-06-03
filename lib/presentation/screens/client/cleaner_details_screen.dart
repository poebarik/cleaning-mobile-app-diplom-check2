import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../providers/cleaner_provider.dart';
import '../../../routes/route_names.dart';

class CleanerDetailsScreen extends ConsumerStatefulWidget {
  final int cleanerId;
  const CleanerDetailsScreen({super.key, required this.cleanerId});

  @override
  ConsumerState<CleanerDetailsScreen> createState() => _CleanerDetailsScreenState();
}

class _CleanerDetailsScreenState extends ConsumerState<CleanerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cleanerProvider.notifier).loadCleanerDetails(widget.cleanerId);
    });
  }

  void _inviteCleaner() {
    final extra = ModalRoute.of(context)?.settings.arguments as Map?;
    final orderId = extra?['orderId'] as int?;

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось определить заказ')),
      );
      return;
    }

    // Переходим на экран создания приглашения
    context.push(
      '${RouteNames.createInvitation}/$orderId/${widget.cleanerId}',
      extra: {
        'cleanerName': ref.read(cleanerProvider).cleaner?.fullName,
        'cleanerRating': ref.read(cleanerProvider).cleaner?.rating,
      },
    );
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
            _buildAvatarAndInfo(cleaner),
            const SizedBox(height: 24),
            if (cleaner.pricePerHour != null) _buildPriceCard(cleaner),
            const SizedBox(height: 24),
            if (cleaner.bio != null && cleaner.bio!.isNotEmpty) _buildBio(cleaner),
            const SizedBox(height: 24),
            if (cleaner.services != null && cleaner.services!.isNotEmpty)
              _buildServices(cleaner),
            const SizedBox(height: 24),
            _buildInviteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarAndInfo(dynamic cleaner) {
    return Center(
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
          if (cleaner.isAvailable != null) const SizedBox(height: 8),
          if (cleaner.isAvailable != null)
            Center(
              child: StatusChip(
                status: cleaner.isAvailable! ? 'OPEN' : 'CANCELLED',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(dynamic cleaner) {
    return Container(
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
    );
  }

  Widget _buildBio(dynamic cleaner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildServices(dynamic cleaner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildInviteButton() {
    return CustomButton(
      onPressed: _inviteCleaner,
      text: 'Пригласить этого клинера',
    );
  }
}