import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/enums/order_creation_type.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../routes/route_names.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  OrderCreationType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать заказ'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Выберите способ создания заказа',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'У нас есть 3 способа найти вам идеального клинера',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            _buildOptionCard(
              context,
              type: OrderCreationType.companyCleaners,
              icon: Icons.business_center,
              color: Colors.blue,
              description: 'Компания сама назначит клинера',
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              type: OrderCreationType.browseCleaners,
              icon: Icons.people_alt,
              color: Colors.green,
              description: 'Выберите клинера из списка с отзывами',
            ),
            const SizedBox(height: 16),
            _buildOptionCard(
              context,
              type: OrderCreationType.marketplace,
              icon: Icons.campaign,
              color: Colors.orange,
              description: 'Клинеры сами откликнутся на заказ',
            ),
            const SizedBox(height: 32),
            CustomButton(
              onPressed: _selectedType != null
                  ? () => _navigateToOrderForm(context)
                  : null,
              text: 'Продолжить',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required OrderCreationType type,
        required IconData icon,
        required Color color,
        required String description,
      }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToOrderForm(BuildContext context) {
    switch (_selectedType) {
      case OrderCreationType.companyCleaners:
      // Переход на экран создания заказа через компанию
        context.push(RouteNames.createCompanyOrder);
        break;
      case OrderCreationType.browseCleaners:
      // Переход на экран выбора клинера
        context.push(RouteNames.cleanerList);
        break;
      case OrderCreationType.marketplace:
      // Переход на экран создания маркетплейс заказа
        context.push(RouteNames.createMarketplaceOrder);
        break;
      default:
        break;
    }
  }
}