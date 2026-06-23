// lib/presentation/screens/client/draft_order/draft_order_screen.dart (обновленный)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/database/hive_service.dart';
import '../../../../core/database/order_draft_datasource.dart';
import '../../../data/models/order/order_draft.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../providers/order_wizard_provider.dart';
import '../../providers/usecase_providers.dart';
import '../../../shared/widgets/draft_order/draft_section.dart';
import '../../../shared/widgets/draft_order/draft_header.dart';
import '../../../shared/widgets/draft_order/draft_card.dart';

import 'create_order_wizard/steps/step_0_address.dart';
import 'create_order_wizard/steps/step_date_time.dart';
import 'create_order_wizard/steps/step_1_preferences.dart';
import 'create_order_wizard/steps/step_2_pricing.dart';
import 'create_order_wizard/steps/step_3_location.dart';
import 'create_order_wizard/steps/step_4_cleaning_type.dart';
import 'create_order_wizard/steps/step_5_area.dart';
import 'create_order_wizard/steps/step_6_rooms.dart';
import 'create_order_wizard/steps/step_7_services.dart';
import 'create_order_wizard/steps/step_8_inventory.dart';
import 'create_order_wizard/steps/step_9_price_limit.dart';
import 'create_order_wizard/steps/step_10_notes.dart';


class DraftOrderScreen extends ConsumerStatefulWidget {
  final String? initialCleaningType;
  final String? initialTemplateName;
  final int? serviceId;
  final String? serviceName;
  final double? servicePrice;
  final String? serviceDescription;
  final String? cleaningType;

  const DraftOrderScreen({
    super.key,
    this.initialCleaningType,
    this.initialTemplateName,
    this.serviceId,
    this.serviceName,
    this.servicePrice,
    this.serviceDescription,
    this.cleaningType,
  });

  @override
  ConsumerState<DraftOrderScreen> createState() => _DraftOrderScreenState();
}

class _DraftOrderScreenState extends ConsumerState<DraftOrderScreen> {
  late OrderWizardNotifier _wizardNotifier;
  final OrderDraftDataSource _dataSource = OrderDraftDataSource();
  OrderDraft? _currentDraft;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _initialParamsApplied = false;
  int _refreshCounter = 0;

  // ✅ Добавляем переменную для хранения названия услуги
  String? _selectedServiceName;

  @override
  void initState() {
    super.initState();
    _initHiveAndLoadDraft();
  }

  Future<void> _initHiveAndLoadDraft() async {
    await HiveService.init();
    await _loadDraft();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadDraft() async {
    _currentDraft = await _dataSource.getCurrentDraft();
    if (_currentDraft != null && _currentDraft!.hasData) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showResumeDialog());
    }
    _initWizardFromDraft();
  }

  // lib/presentation/screens/client/draft_order/draft_order_screen.dart

  void _initWizardFromDraft() {
    _wizardNotifier = OrderWizardNotifier(
      serviceId: _currentDraft?.serviceId ?? 1,
      address: _currentDraft?.address ?? '',
      orderDate: _currentDraft?.orderDate ?? DateTime.now().add(const Duration(days: 1)),
      cleanerId: _currentDraft?.cleanerId,
    );

    final d = _currentDraft;
    if (d == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyInitialParams();
      });
      return;
    }

    print('📸 ВОССТАНОВЛЕНИЕ ИЗ ЧЕРНОВИКА:');
    print('  - cleaningType: ${d.cleaningType}');
    print('  - serviceName: ${d.serviceName}');  // ✅ Добавляем

    // ✅ Восстанавливаем serviceName из черновика
    if (d.serviceName != null && d.serviceName!.isNotEmpty) {
      _selectedServiceName = d.serviceName;
      _wizardNotifier.updateServiceName(d.serviceName);
    }

    if (d.creationType != null) {
      OrderCreationType type;
      switch (d.creationType) {
        case 'limitedBids':
          type = OrderCreationType.limitedBids;
          break;
        case 'openMarket':
          type = OrderCreationType.openMarket;
          break;
        case 'companyAssigned':
          type = OrderCreationType.companyAssigned;
          break;
        case 'directInvitation':
          type = OrderCreationType.directInvitation;
          break;
        default:
          type = OrderCreationType.companyAssigned;
      }
      _wizardNotifier.updateCreationType(type);
    }

    if (d.cleaningType != null && d.cleaningType!.isNotEmpty) {
      _wizardNotifier.updateCleaningType(d.cleaningType!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyInitialParams();
    });
  }

  void _applyInitialParams() {
    if (_initialParamsApplied) return;
    _initialParamsApplied = true;

    print('📸 ПРИМЕНЕНИЕ НАЧАЛЬНЫХ ПАРАМЕТРОВ:');
    print('  - cleaningType: ${widget.cleaningType}');
    print('  - serviceName: ${widget.serviceName}');
    print('  - serviceId: ${widget.serviceId}');
    print('  - servicePrice: ${widget.servicePrice}');

    bool hasChanges = false;

    // ✅ Сохраняем название услуги и обновляем Wizard
    if (widget.serviceName != null && widget.serviceName!.isNotEmpty) {
      _selectedServiceName = widget.serviceName;
      _wizardNotifier.updateServiceName(widget.serviceName); // ✅ Сохраняем в Wizard
      print('📸 Сохраняем название услуги: $_selectedServiceName');
      hasChanges = true;
    }

    // ✅ Приоритет: cleaningType > initialCleaningType
    final cleaningType = widget.cleaningType ?? widget.initialCleaningType;

    if (cleaningType != null && cleaningType.isNotEmpty) {
      print('📸 Применяем cleaningType: $cleaningType');
      _wizardNotifier.updateCleaningType(cleaningType);
      hasChanges = true;
    }

    // ✅ НЕ добавляем serviceName в заметки - теперь он отображается в шаге 5

    if (widget.serviceId != null) {
      print('📸 Применяем serviceId: ${widget.serviceId}');
      _wizardNotifier.updateServiceId(widget.serviceId!);
      hasChanges = true;
    }

    if (widget.servicePrice != null) {
      print('📸 Применяем servicePrice: ${widget.servicePrice}');
      _wizardNotifier.updatePricingMode(PricingMode.fixed);
      _wizardNotifier.updateFixedPrice(widget.servicePrice!);
      hasChanges = true;
    }

    _saveDraft();

    if (hasChanges && mounted) {
      setState(() {
        _refreshCounter++;
      });
      print('📸 UI обновлен, counter: $_refreshCounter');
    }
  }

  void _showResumeDialog() {
    if (!mounted) return;
    final draft = _currentDraft!;
    final hours = DateTime.now().difference(draft.updatedAt).inHours;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Продолжить создание заказа?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('У вас есть незавершённый заказ'),
            const SizedBox(height: 6),
            Text(
              'Сохранён ${hours > 0 ? '$hours ч. назад' : 'менее часа назад'}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _dataSource.deleteCurrentDraft();
              _currentDraft = null;
              _initWizardFromDraft();
              if (mounted) {
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: const Text('Удалить',
                style: TextStyle(color: Colors.redAccent)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _applyInitialParams();
              });
            },
            child: const Text('Продолжить'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft() async {
    final s = _wizardNotifier.state;
    print('📸 СОХРАНЕНИЕ ЧЕРНОВИКА:');
    print('  - cleaningType: ${s.cleaningType}');
    print('  - notes: ${s.notes}');

    final draft = OrderDraft(
      id: _currentDraft?.id ?? _dataSource.generateId(),
      serviceId: s.serviceId,
      serviceName: s.serviceName,
      address: s.address,
      orderDate: s.orderDate,
      updatedAt: DateTime.now(),
      cleanerId: s.cleanerId,
      creationType: s.creationType?.toString().split('.').last,
      pricingMode: s.pricingMode?.toString().split('.').last,
      fixedPrice: s.fixedPrice,
      locationType: s.locationType,
      locationCustom: s.locationCustom,
      cleaningType: s.cleaningType,
      area: s.area,
      rooms: s.rooms,
      roomsCustom: s.roomsCustom,
      additionalServices: s.additionalServices,
      customServices: s.customServices,
      inventory: s.inventory,
      maxPrice: s.maxPrice,
      notes: s.notes,
      imageObjectNames: s.imageObjectNames ?? [],
    );

    await _dataSource.saveCurrentDraft(draft);
    _currentDraft = draft;
  }

  Future<void> _submitOrder() async {
    final wizardState = _wizardNotifier.state;

    print('📸 ПЕРЕД ОТПРАВКОЙ ЗАКАЗА:');
    print('  - creationType: ${wizardState.creationType}');
    print('  - cleaningType: ${wizardState.cleaningType}');

    if (!wizardState.isValid) {
      CustomSnackbar.showError(context, 'Пожалуйста, заполните все обязательные поля');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final request = wizardState.toRequest();

      print('========== ОТПРАВКА ЗАКАЗА ==========');
      print('FulfillmentType: ${request.fulfillmentType}');
      print('CreationType: ${wizardState.creationType}');
      print('CleanerId: ${request.cleanerId}');
      print('budget: ${request.budget}');
      print('=====================================');

      final orderRepository = ref.read(orderRepositoryProvider);
      final order = await orderRepository.createOrderWithMode(request);

      print('✅ Order created: ${order.id}');

      await _saveDraft();
      await _dataSource.deleteCurrentDraft();

      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Заказ успешно создан!');

        final isDirectInvitation = wizardState.creationType == OrderCreationType.directInvitation;

        if (isDirectInvitation) {
          context.go('/select-cleaner/${order.id}');
        } else {
          context.go('/order-details/${order.id}');
        }
      }
    } catch (e) {
      print('❌ Ошибка создания заказа: $e');
      if (e is DioException) {
        print('Response: ${e.response?.data}');
      }
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка создания заказа: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openStepSheet(int stepIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => _WizardBottomSheet(
        wizardNotifier: _wizardNotifier,
        initialStep: stepIndex,
        onSave: () async {
          await _saveDraft();
          if (mounted) {
            setState(() {});
          }
        },
        ref: ref,
      ),
    );
  }

  String _creationTypeText(OrderCreationType? t) {
    switch (t) {
      case OrderCreationType.limitedBids:
        return 'До 6 предложений';
      case OrderCreationType.openMarket:
        return 'Открытый рынок';
      case OrderCreationType.companyAssigned:
        return 'Выбор компании';
      case OrderCreationType.directInvitation:
        return 'Пригласить клинера';
      default:
        return '';
    }
  }

  String _pricingText(OrderWizardState s) {
    if (s.pricingMode == PricingMode.fixed) {
      return 'Фиксированная: ${s.fixedPrice?.toInt() ?? '—'} ₸';
    }
    if (s.pricingMode == PricingMode.bidding) return 'Торг';
    return '';
  }

  String _locationText(OrderWizardState s) {
    if (s.locationType == 'CUSTOM') return s.locationCustom ?? 'Другое';
    const map = {
      'APARTMENT': 'Квартира',
      'HOUSE': 'Дом',
      'OFFICE': 'Офис',
      'COMMERCIAL': 'Коммерческое',
    };
    return map[s.locationType] ?? s.locationType;
  }

  String _cleaningTypeText(String t) {
    const map = {
      'MAINTENANCE': 'Поддерживающая',
      'DEEP_CLEANING': 'Генеральная',
      'AFTER_RENOVATION': 'После ремонта',
      'MOVE_IN': 'Перед заселением',
      'MOVE_OUT': 'После выезда',
    };
    return map[t] ?? t;
  }

  // ✅ Метод для получения отображаемого текста типа уборки
  String _getCleaningTypeDisplayText(String cleaningType) {
    // Если есть название услуги - показываем его
    if (_selectedServiceName != null && _selectedServiceName!.isNotEmpty) {
      return _selectedServiceName!;
    }

    // Иначе показываем стандартное название
    const map = {
      'MAINTENANCE': 'Поддерживающая',
      'DEEP_CLEANING': 'Генеральная',
      'AFTER_RENOVATION': 'После ремонта',
      'MOVE_IN': 'Перед заселением',
      'MOVE_OUT': 'После выезда',
      'CUSTOM': 'Индивидуальная',
    };
    return map[cleaningType] ?? cleaningType;
  }

  String _inventoryText(String t) {
    const map = {
      'CLIENT': 'Мой инвентарь',
      'CLEANER': 'Инвентарь клинера',
      'PARTIAL': 'Частично',
    };
    return map[t] ?? t;
  }

  String _roomsWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'комната';
    if (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) {
      return 'комнаты';
    }
    return 'комнат';
  }

  String _dateTimeText(DateTime dt) {
    final d = '${dt.day}.${dt.month}.${dt.year}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d, $t';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final s = _wizardNotifier.state;
    final theme = Theme.of(context);

    // ✅ Получаем отображаемый текст
    final cleaningTypeDisplayText = _getCleaningTypeDisplayText(s.cleaningType);

    print('📸 BUILD DraftOrderScreen:');
    print('  - cleaningType: ${s.cleaningType}');
    print('  - displayText: $cleaningTypeDisplayText');
    print('  - serviceName: $_selectedServiceName');

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: DraftHeader(onClose: () => Navigator.pop(context)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: Row(
                children: [
                  Icon(Icons.edit_note,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 5),
                  Text(
                    'Черновик',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DraftSection(
                  title: 'Основная информация',
                  children: [
                    DraftCard(
                      icon: Icons.location_on_outlined,
                      title: 'Адрес',
                      value: s.address.isNotEmpty ? s.address : null,
                      placeholder: 'Укажите адрес',
                      onTap: () => _openStepSheet(0),
                    ),
                    DraftCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Дата и время',
                      value: _dateTimeText(s.orderDate),
                      placeholder: 'Выберите дату и время',
                      onTap: () => _openStepSheet(1),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                DraftSection(
                  title: 'Главное о задаче',
                  children: [
                    DraftCard(
                      icon: Icons.tune,
                      title: 'Тип заказа',
                      value: s.creationType != null
                          ? _creationTypeText(s.creationType)
                          : null,
                      placeholder: 'Как получить предложения?',
                      onTap: () => _openStepSheet(2),
                    ),
                    if (s.creationType != OrderCreationType.companyAssigned)
                      DraftCard(
                        icon: Icons.payments_outlined,
                        title: 'Цена',
                        value: s.pricingMode != null ? _pricingText(s) : null,
                        placeholder: 'Как определить цену?',
                        onTap: () => _openStepSheet(3),
                      ),
                    DraftCard(
                      icon: Icons.apartment_outlined,
                      title: 'Тип помещения',
                      value: _locationText(s),
                      placeholder: 'Квартира, дом, офис...',
                      onTap: () => _openStepSheet(4),
                    ),
                    // ✅ КАРТОЧКА ТИПА УБОРКИ - с отображением названия услуги
                    DraftCard(
                      key: ValueKey('cleaningType_${s.cleaningType}_$_refreshCounter'),
                      icon: Icons.cleaning_services_outlined,
                      title: 'Тип уборки',
                      value: cleaningTypeDisplayText, // ✅ Показываем название услуги
                      placeholder: 'Какая уборка нужна?',
                      onTap: () => _openStepSheet(5),
                    ),
                    DraftCard(
                      icon: Icons.square_foot,
                      title: 'Площадь',
                      value: s.area != null ? '${s.area} м²' : null,
                      placeholder: 'Укажите площадь',
                      onTap: () => _openStepSheet(6),
                    ),
                    DraftCard(
                      icon: Icons.meeting_room_outlined,
                      title: 'Комнаты',
                      value: s.rooms.isNotEmpty
                          ? '${s.rooms.length} ${_roomsWord(s.rooms.length)}'
                          : null,
                      subtitle: s.roomsCustom,
                      placeholder: 'Какие комнаты убрать?',
                      onTap: () => _openStepSheet(7),
                    ),
                    DraftCard(
                      icon: Icons.add_circle_outline,
                      title: 'Доп. услуги',
                      value: s.additionalServices.isNotEmpty
                          ? '${s.additionalServices.length} услуг'
                          : null,
                      subtitle: s.customServices.isNotEmpty
                          ? s.customServices.join(', ')
                          : null,
                      placeholder: 'Мытьё окон, духовка...',
                      onTap: () => _openStepSheet(8),
                    ),
                    DraftCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Инвентарь',
                      value: s.inventory != 'CLIENT'
                          ? _inventoryText(s.inventory)
                          : null,
                      placeholder: 'Кто предоставит инвентарь?',
                      onTap: () => _openStepSheet(9),
                    ),
                    if (s.pricingMode == PricingMode.bidding)
                      DraftCard(
                        icon: Icons.price_change_outlined,
                        title: 'Максимальная цена',
                        value: s.maxPrice != null
                            ? 'до ${s.maxPrice!.toInt()} ₸'
                            : null,
                        placeholder: 'Укажите максимальную цену',
                        onTap: () => _openStepSheet(10),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                DraftSection(
                  title: 'Дополнительно',
                  children: [
                    DraftCard(
                      icon: Icons.edit_note,
                      title: 'Пожелания и фото',
                      value: s.notes,
                      placeholder: 'Добавьте комментарий или фото',
                      onTap: () => _openStepSheet(11),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                CustomButton(
                  onPressed: _submitOrder,
                  text: 'Создать заказ',
                  isLoading: _isSubmitting,
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _WizardBottomSheet
// ============================================================================

class _WizardBottomSheet extends StatefulWidget {
  final OrderWizardNotifier wizardNotifier;
  final int initialStep;
  final Future<void> Function() onSave;
  final WidgetRef ref;

  const _WizardBottomSheet({
    required this.wizardNotifier,
    required this.initialStep,
    required this.onSave,
    required this.ref,
  });

  @override
  State<_WizardBottomSheet> createState() => _WizardBottomSheetState();
}

class _WizardBottomSheetState extends State<_WizardBottomSheet> {
  late PageController _pageController;
  late int _currentStep;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _pageController = PageController(initialPage: _currentStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _nextStep() async {
    await widget.onSave();

    if (_currentStep < 11) {
      setState(() => _currentStep++);
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      if (mounted) {
        if (widget.wizardNotifier.state.isValid) {
          CustomSnackbar.showSuccess(context, 'Все данные заполнены! Нажмите "Создать заказ"');
          Navigator.pop(context);
        } else {
          CustomSnackbar.showError(context, 'Заполните все обязательные поля');
        }
      }
    }
  }

  void _previousStep() async {
    await widget.onSave();

    if (_currentStep > 0) {
      setState(() => _currentStep--);
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wizardState = widget.wizardNotifier.state;

    final steps = [
      StepAddress(notifier: widget.wizardNotifier, state: wizardState),
      StepDateTime(notifier: widget.wizardNotifier, state: wizardState),
      Step2Pricing(notifier: widget.wizardNotifier, state: wizardState),
      Step3Location(notifier: widget.wizardNotifier, state: wizardState),
      Step4CleaningType(notifier: widget.wizardNotifier, state: wizardState),
      Step5Area(notifier: widget.wizardNotifier, state: wizardState),
      Step6Rooms(notifier: widget.wizardNotifier, state: wizardState),
      Step7Services(notifier: widget.wizardNotifier, state: wizardState),
      Step8Inventory(notifier: widget.wizardNotifier, state: wizardState),
      Step9PriceLimit(notifier: widget.wizardNotifier, state: wizardState),
      Step10Notes(notifier: widget.wizardNotifier, state: wizardState),
      Step1Preferences(notifier: widget.wizardNotifier, state: wizardState),
    ];

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            LinearProgressIndicator(
              value: (_currentStep + 1) / steps.length,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Шаг ${_currentStep + 1} из ${steps.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (wizardState.isValid)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          const Text('Готово', style: TextStyle(fontSize: 12, color: Colors.green)),
                        ],
                      ),
                    ),
                  IconButton(
                    onPressed: () async {
                      await widget.onSave();
                      if (mounted) Navigator.pop(context);
                    },
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentStep = index);
                },
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: steps[index],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
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
                      text: _currentStep == steps.length - 1
                          ? 'Готово'
                          : 'Далее',
                      isLoading: _isSubmitting,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}