import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../routes/route_names.dart';
import '../../providers/manager_provider.dart';

class AssignCleanerScreen extends ConsumerStatefulWidget {
  final int orderId;
  const AssignCleanerScreen({super.key, required this.orderId});

  @override
  ConsumerState<AssignCleanerScreen> createState() => _AssignCleanerScreenState();
}

class _AssignCleanerScreenState extends ConsumerState<AssignCleanerScreen> {
  int? _selectedCleanerId;
  final TextEditingController _commentController = TextEditingController();
  String? _searchQuery;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(managerProvider.notifier).loadAvailableCleaners();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCleaners {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return ref.read(managerProvider).cleaners ?? [];
    }
    return (ref.read(managerProvider).cleaners ?? []).where((cleaner) {
      final name = cleaner['fullName']?.toLowerCase() ?? '';
      return name.contains(_searchQuery!.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Назначить клинера',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: managerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : managerState.cleaners == null || managerState.cleaners!.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          // Поиск
          _buildSearchBar(),
          const SizedBox(height: 8),
          // Статистика
          _buildStatsBar(_filteredCleaners.length),
          // Список клинеров
          Expanded(
            child: _filteredCleaners.isEmpty
                ? _buildNoResultsState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredCleaners.length,
              itemBuilder: (context, index) {
                final cleaner = _filteredCleaners[index];
                return _buildCleanerCard(cleaner);
              },
            ),
          ),
          // Комментарий
          _buildCommentSection(),
          // Кнопка назначения
          _buildAssignButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Поиск клинера...',
          hintStyle: TextStyle(color: AppColors.textHint),
          prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _searchQuery != null && _searchQuery!.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: AppColors.textSecondary),
            onPressed: () {
              setState(() {
                _searchQuery = null;
              });
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStatsBar(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count доступно',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Выберите клинера',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanerCard(Map<String, dynamic> cleaner) {
    final isSelected = _selectedCleanerId == cleaner['id'];
    final rating = (cleaner['rating'] ?? 0).toDouble();
    final completedOrders = cleaner['completedOrders'] ?? 0;
    final price = cleaner['pricePerHour'] ?? cleaner['experienceYears'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.divider,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedCleanerId = cleaner['id'];
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.gradient),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      cleaner['fullName']?.substring(0, 1) ?? '?',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleaner['fullName'] ?? 'Клинер',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _buildInfoChip(Icons.star_rate_rounded, rating.toStringAsFixed(1), AppColors.warning),
                          const SizedBox(width: 8),
                          _buildInfoChip(Icons.cleaning_services_rounded, '$completedOrders уборок', AppColors.primary),
                          if (price > 0) ...[
                            const SizedBox(width: 8),
                            _buildInfoChip(Icons.work_outline, '$price ₽/час', AppColors.secondary),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Радио кнопка
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.textHint,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Комментарий (опционально)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Добавьте инструкции или комментарий для клинера...',
              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignButton() {
    final isSelected = _selectedCleanerId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomButton(
        onPressed: isSelected && !_isAssigning
            ? () async {
          setState(() => _isAssigning = true);
          await ref
              .read(managerProvider.notifier)
              .assignCleaner(widget.orderId, _selectedCleanerId!

          );
          setState(() => _isAssigning = false);
          if (context.mounted) {
            CustomSnackbar.showSuccess(context, 'Клинер успешно назначен');
            context.go(RouteNames.managerDashboard);
          }
        }
            : null,
        text: _isAssigning ? 'Назначение...' : 'Назначить клинера',
        isLoading: _isAssigning,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Нет доступных клинеров',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Все клинеры сейчас заняты.\nПопробуйте позже',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          CustomButton(
            onPressed: () {
              ref.read(managerProvider.notifier).loadAvailableCleaners();
            },
            text: 'Обновить',
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
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
            child: const Icon(Icons.search_off, size: 40, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          Text(
            'Ничего не найдено',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить поисковый запрос',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}