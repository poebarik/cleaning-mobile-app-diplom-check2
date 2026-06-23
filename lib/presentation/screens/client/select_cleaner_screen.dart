// lib/presentation/screens/client/select_cleaner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/cleaner_repository.dart';
import '../../../data/models/cleaner/cleaner.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../routes/route_names.dart';
import '../../providers/invitation_provider.dart';
import '../../providers/usecase_providers.dart';
import '../../../domain/enums/order_action.dart';
import '../../../data/repositories/order_repository.dart';

class SelectCleanerScreen extends ConsumerStatefulWidget {
  final int orderId;
  final double? budget;

  const SelectCleanerScreen({
    super.key,
    required this.orderId,
    this.budget,
  });

  @override
  ConsumerState<SelectCleanerScreen> createState() => _SelectCleanerScreenState();
}

class _SelectCleanerScreenState extends ConsumerState<SelectCleanerScreen> {
  final CleanerRepository _cleanerRepository = CleanerRepository();

  List<Cleaner> _cleaners = [];
  bool _isLoading = true;
  String? _error;
  int? _selectedCleanerId;
  bool _isInviting = false;

  @override
  void initState() {
    super.initState();
    print('🔍 SelectCleanerScreen opened!');
    print('  - orderId: ${widget.orderId}');
    print('  - budget: ${widget.budget}');
    _loadCleaners();
  }

  Future<void> _loadCleaners() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cleaners = await _cleanerRepository.getCleaners();
      setState(() {
        _cleaners = cleaners.where((c) => c.isAvailable == true).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // lib/presentation/screens/client/select_cleaner_screen.dart

  Future<void> _inviteCleaner(int cleanerId) async {
    setState(() => _isInviting = true);

    try {
      double? budget = widget.budget;
      if (budget == null || budget == 0) {
        try {
          // ✅ Используем провайдер вместо new OrderRepository()
          final orderRepository = ref.read(orderRepositoryProvider);
          final order = await orderRepository.getOrderById(widget.orderId);
          budget = order.budget ?? order.specification?.price ?? order.specification?.maxPrice ?? 0;
        } catch (e) {
          print('⚠️ Не удалось получить бюджет заказа: $e');
          budget = 0;
        }
      }

      print('📤 SENDING INVITATION:');
      print('  - orderId: ${widget.orderId}');
      print('  - cleanerId: $cleanerId');
      print('  - budget: $budget');

      final invitationRepository = ref.read(invitationRepositoryProvider);

      await invitationRepository.createInvitation(
        orderId: widget.orderId,
        cleanerId: cleanerId,
        proposedPrice: budget,
        message: 'Приглашаем вас на уборку',
      );

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Приглашение отправлено!');
        context.go('/order/${widget.orderId}');
      }
    } catch (e) {
      print('❌ Error sending invitation: $e');
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isInviting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Выберите клинера', style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/order/${widget.orderId}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? _buildShimmer()
          : _error != null
          ? _buildError()
          : _cleaners.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
        onRefresh: _loadCleaners,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _cleaners.length,
          itemBuilder: (context, index) {
            final cleaner = _cleaners[index];
            return _buildCleanerCard(cleaner);
          },
        ),
      ),
    );
  }

  Widget _buildCleanerCard(Cleaner cleaner) {
    final isSelected = _selectedCleanerId == cleaner.id;
    final isVerified = cleaner.verificationStatus == 'VERIFIED';
    final verifiedFields = _getVerifiedFields(cleaner);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => setState(() => _selectedCleanerId = cleaner.id),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Шапка с аватаркой и именем
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: cleaner.avatarUrl != null && cleaner.avatarUrl!.isNotEmpty
                                ? DecorationImage(
                              image: NetworkImage(cleaner.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                                : null,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: cleaner.avatarUrl == null || cleaner.avatarUrl!.isEmpty
                              ? CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              cleaner.fullName[0].toUpperCase(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          )
                              : null,
                        ),
                        if (isVerified)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cleaner.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Верифицирован',
                                    style: TextStyle(fontSize: 9, color: AppColors.success, fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rate_rounded, size: 16, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text(
                                cleaner.rating?.toStringAsFixed(1) ?? '0',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(width: 12),
                              const Icon(Icons.cleaning_services_rounded, size: 14, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(
                                '${cleaner.completedOrders ?? 0} уборок',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cleaner.isAvailable == true
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  cleaner.isAvailable == true ? 'Доступен' : 'Занят',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: cleaner.isAvailable == true ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Блок верификации
                if (isVerified && verifiedFields.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: verifiedFields.map((field) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified, size: 12, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              field,
                              style: const TextStyle(fontSize: 10, color: AppColors.success),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],

                // Специализация
                if (cleaner.bio != null && cleaner.bio!.isNotEmpty) ...[
                  Text(
                    cleaner.bio!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                ],

                // Опыт и цена
                Row(
                  children: [
                    if (cleaner.experienceYears != null) ...[
                      Icon(Icons.work_history, size: 16, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(
                        '${cleaner.experienceYears} лет опыта',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      'от ${cleaner.price ?? cleaner.pricePerHour ?? 0} ₸',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Кнопки
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/profile/${cleaner.id}');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Посмотреть профиль'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isInviting ? null : () => _inviteCleaner(cleaner.id),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isInviting && _selectedCleanerId == cleaner.id
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Пригласить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getVerifiedFields(Cleaner cleaner) {
    final fields = <String>[];
    if (cleaner.identityVerified == true) fields.add('Паспорт');
    if (cleaner.criminalRecordVerified == true) fields.add('Справка о несудимости');
    if (cleaner.medicalCertificateVerified == true) fields.add('Медицинская справка');
    return fields;
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const ShimmerLoadingCard(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Ошибка: $_error'),
          const SizedBox(height: 16),
          CustomButton(
            onPressed: _loadCleaners,
            text: 'Повторить',
          ),
        ],
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
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, size: 50, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет доступных клинеров',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Попробуйте обновить список',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class ShimmerLoadingCard extends StatelessWidget {
  const ShimmerLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: double.infinity, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 100, color: Colors.grey[300]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 40, width: double.infinity, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Container(height: 40, color: Colors.grey[300])),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 40, color: Colors.grey[300])),
            ],
          ),
        ],
      ),
    );
  }
}