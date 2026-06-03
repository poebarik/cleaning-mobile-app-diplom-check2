import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/enums/order_creation_type.dart';
import '../../../routes/route_names.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  OrderCreationType? _selectedType;

  final _options = [
    {
      'type': OrderCreationType.companyCleaners,
      'icon': Icons.business_center_rounded,
      'gradient': [const Color(0xFF6C5CE7), const Color(0xFF8B7FF0)],
      'title': 'Через компанию',
      'subtitle': 'Компания назначит лучшего клинера',
      'badge': 'Быстро',
      'badgeColor': const Color(0xFFE8F4FD),
      'badgeTextColor': const Color(0xFF0984E3),
    },
    {
      'type': OrderCreationType.browseCleaners,
      'icon': Icons.people_alt_rounded,
      'gradient': [const Color(0xFF0984E3), const Color(0xFF74B9FF)],
      'title': 'Выбрать клинера',
      'subtitle': 'Просмотрите профили и выберите сами',
      'badge': 'Популярно',
      'badgeColor': const Color(0xFFE8F8F5),
      'badgeTextColor': const Color(0xFF00B894),
    },
    {
      'type': OrderCreationType.marketplace,
      'icon': Icons.campaign_rounded,
      'gradient': [const Color(0xFFE17055), const Color(0xFFFD79A8)],
      'title': 'Маркетплейс',
      'subtitle': 'Клинеры сами откликнутся и предложат цену',
      'badge': 'Выгодно',
      'badgeColor': const Color(0xFFFFF3E0),
      'badgeTextColor': const Color(0xFFE17055),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppColors.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Создать заказ', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
                        const SizedBox(height: 4),
                        const Text('Выберите удобный способ', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Способ создания', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('У нас 3 способа найти идеального клинера', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 20),
                  ..._options.map((opt) => _buildOptionCard(opt)),
                  const SizedBox(height: 24),
                  AnimatedOpacity(
                    opacity: _selectedType != null ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _selectedType != null ? AppColors.gradient : [AppColors.textHint, AppColors.textHint],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _selectedType != null ? [
                            BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                          ] : [],
                        ),
                        child: ElevatedButton(
                          onPressed: _selectedType != null ? () => _navigate() : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Продолжить', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(Map<String, dynamic> opt) {
    final type = opt['type'] as OrderCreationType;
    final isSelected = _selectedType == type;
    final gradientColors = opt['gradient'] as List<Color>;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? gradientColors.first : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? gradientColors.first.withOpacity(0.2) : AppColors.shadow,
              blurRadius: isSelected ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(opt['icon'] as IconData, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        opt['title'] as String,
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: opt['badgeColor'] as Color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          opt['badge'] as String,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'Poppins', color: opt['badgeTextColor'] as Color),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt['subtitle'] as String,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? gradientColors.first : Colors.transparent,
                border: Border.all(
                  color: isSelected ? gradientColors.first : AppColors.textHint,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _navigate() {
    switch (_selectedType) {
      case OrderCreationType.companyCleaners:
        context.push(RouteNames.createCompanyOrder);
        break;
      case OrderCreationType.browseCleaners:
        context.push(RouteNames.cleanerList);
        break;
      case OrderCreationType.marketplace:
        context.push(RouteNames.createMarketplaceOrder);
        break;
      default:
        break;
    }
  }
}