// lib/presentation/screens/client/create_order_wizard/create_order_wizard_screen.dart
import 'package:cleaning_mobile_application/presentation/screens/client/create_order_wizard/steps/step_0_address.dart';
import 'package:cleaning_mobile_application/presentation/screens/client/create_order_wizard/steps/step_date_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/order_wizard_provider.dart';
import '../../../providers/usecase_providers.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import 'steps/step_1_preferences.dart';
import 'steps/step_2_pricing.dart';
import 'steps/step_3_location.dart';
import 'steps/step_4_cleaning_type.dart';
import 'steps/step_5_area.dart';
import 'steps/step_6_rooms.dart';
import 'steps/step_7_services.dart';
import 'steps/step_8_inventory.dart';
import 'steps/step_9_price_limit.dart';
import 'steps/step_10_notes.dart';

class CreateOrderWizardScreen extends ConsumerStatefulWidget {
  final int serviceId;
  final String address;
  final DateTime orderDate;
  final int? cleanerId;

  const CreateOrderWizardScreen({
    super.key,
    required this.serviceId,
    required this.address,
    required this.orderDate,
    this.cleanerId,
  });

  @override
  ConsumerState<CreateOrderWizardScreen> createState() => _CreateOrderWizardScreenState();
}

class _CreateOrderWizardScreenState extends ConsumerState<CreateOrderWizardScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  bool _isSubmitting = false;
  late OrderWizardNotifier _wizardNotifier;

  @override
  void initState() {
    super.initState();
    // ✅ Создаем notifier с параметрами
    _wizardNotifier = OrderWizardNotifier(
      serviceId: widget.serviceId,
      address: widget.address,
      orderDate: widget.orderDate,
      cleanerId: widget.cleanerId,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _wizardNotifier.dispose(); // ✅ Не забываем dispose
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final wizardState = _wizardNotifier.state;

    if (!wizardState.isValid) {
      CustomSnackbar.showError(context, 'Пожалуйста, заполните все обязательные поля');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = wizardState.toRequest();

      // ✅ ДОБАВЛЯЕМ ЛОГИРОВАНИЕ ЗАПРОСА
      print('========== ОТПРАВКА ЗАКАЗА ==========');
      print('ServiceId: ${request.serviceId}');
      print('Address: ${request.address}');
      print('OrderDate: ${request.orderDate}');
      print('FulfillmentType: ${request.fulfillmentType}');
      print('Budget: ${request.budget}');
      print('CleanerId: ${request.cleanerId}');
      print('Description: ${request.description}');
      print('Specification: ${request.specification.toJson()}');
      print('=====================================');

      final orderRepository = ref.read(orderRepositoryProvider);
      final order = await orderRepository.createOrderWithMode(request);

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Заказ успешно создан!');
        context.go('/order/${order.id}');
      }
    } catch (e) {
      print('❌ Ошибка создания заказа: $e');
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка создания заказа: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _nextStep() {
    if (_currentStep < 9) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitOrder();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = _wizardNotifier.state;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание заказа'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / 12,
                backgroundColor: theme.colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Шаг ${_currentStep + 1} из 10',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (wizardState.isValid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Готово',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StepAddress(notifier: _wizardNotifier, state: wizardState),  // Шаг 0 - адрес с картой
                StepDateTime(notifier: _wizardNotifier, state: wizardState), // Шаг 1 - дата и время
                Step1Preferences(notifier: _wizardNotifier, state: wizardState),
                Step2Pricing(notifier: _wizardNotifier, state: wizardState),
                Step3Location(notifier: _wizardNotifier, state: wizardState),
                Step4CleaningType(notifier: _wizardNotifier, state: wizardState),
                Step5Area(notifier: _wizardNotifier, state: wizardState),
                Step6Rooms(notifier: _wizardNotifier, state: wizardState),
                Step7Services(notifier: _wizardNotifier, state: wizardState),
                Step8Inventory(notifier: _wizardNotifier, state: wizardState),
                Step9PriceLimit(notifier: _wizardNotifier, state: wizardState),
                Step10Notes(notifier: _wizardNotifier, state: wizardState),  // Шаг 10 - заметки + фото
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: CustomButton(
                      onPressed: _previousStep,
                      text: 'Назад',
                      isOutlined: true,
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    onPressed: _nextStep,
                    text: _currentStep == 11
                        ? (_isSubmitting ? 'Создание...' : 'Создать заказ')
                        : 'Далее',
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}