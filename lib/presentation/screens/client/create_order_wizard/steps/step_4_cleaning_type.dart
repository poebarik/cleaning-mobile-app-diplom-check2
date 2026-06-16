// lib/presentation/screens/client/create_order_wizard/steps/step_4_cleaning_type.dart
import 'package:flutter/material.dart';
import '../../../../providers/order_wizard_provider.dart';

class Step4CleaningType extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;
  final VoidCallback? onStateChanged;

  const Step4CleaningType({
    super.key,
    required this.notifier,
    required this.state,
    this.onStateChanged,
  });

  @override
  State<Step4CleaningType> createState() => _Step4CleaningTypeState();
}

class _Step4CleaningTypeState extends State<Step4CleaningType> {
  late OrderWizardState _currentState;

  final Map<String, Map<String, dynamic>> _cleaningTypes = const {
    'MAINTENANCE': {'icon': Icons.cleaning_services, 'label': 'Поддерживающая', 'desc': 'Регулярная уборка для поддержания чистоты'},
    'DEEP_CLEANING': {'icon': Icons.cleaning_services, 'label': 'Генеральная', 'desc': 'Полная уборка всех уголков помещения'},
    'AFTER_RENOVATION': {'icon': Icons.construction, 'label': 'После ремонта', 'desc': 'Уборка после строительных работ'},
    'MOVE_IN': {'icon': Icons.move_to_inbox, 'label': 'Перед заселением', 'desc': 'Подготовка квартиры к заселению'},
    'MOVE_OUT': {'icon': Icons.output, 'label': 'После выезда', 'desc': 'Уборка после выезда жильцов'},
    'CUSTOM': {'icon': Icons.edit, 'label': 'Другое', 'desc': 'Укажите свой вариант'},
  };

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
  }

  @override
  void didUpdateWidget(Step4CleaningType oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      setState(() {
        _currentState = widget.state;
      });
    }
  }

  void _updateState(VoidCallback update) {
    setState(() {
      update();
      _currentState = widget.notifier.state;
    });
    widget.onStateChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Какая уборка нужна?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите тип уборки',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cleaningTypes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final key = _cleaningTypes.keys.elementAt(index);
              final type = _cleaningTypes[key]!;
              final isSelected = _currentState.cleaningType == key;

              return _buildCleaningOption(
                context: context,
                icon: type['icon'],
                label: type['label'],
                description: type['desc'],
                isSelected: isSelected,
                onTap: () => _updateState(() {
                  widget.notifier.updateCleaningType(key);
                }),
              );
            },
          ),
          if (_currentState.cleaningType == 'CUSTOM') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Вы выбрали "Другое". Пожалуйста, уточните в заметках (шаг 10)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCleaningOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withOpacity(0.3)
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}