// lib/presentation/screens/client/create_order_wizard/steps/step_8_inventory.dart
import 'package:flutter/material.dart';
import '../../../../providers/order_wizard_provider.dart';

class Step8Inventory extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;
  final VoidCallback? onStateChanged;

  const Step8Inventory({
    super.key,
    required this.notifier,
    required this.state,
    this.onStateChanged,
  });

  @override
  State<Step8Inventory> createState() => _Step8InventoryState();
}

class _Step8InventoryState extends State<Step8Inventory> {
  late OrderWizardState _currentState;

  final List<Map<String, dynamic>> inventoryOptions = [
    {'value': 'CLIENT', 'icon': Icons.home, 'label': 'Мой инвентарь', 'desc': 'Использую свои средства и оборудование'},
    {'value': 'CLEANER', 'icon': Icons.cleaning_services, 'label': 'Инвентарь клинера', 'desc': 'Специалист привезёт всё необходимое'},
    {'value': 'PARTIAL', 'icon': Icons.share, 'label': 'Частично', 'desc': 'Обсудим детали в чате'},
  ];

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
  }

  @override
  void didUpdateWidget(Step8Inventory oldWidget) {
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
            'Кто предоставит инвентарь?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите удобный вариант',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ...inventoryOptions.map((option) => _buildInventoryOption(
            context: context,
            icon: option['icon'] as IconData,
            label: option['label'] as String,
            description: option['desc'] as String,
            isSelected: _currentState.inventory == option['value'],
            onTap: () => _updateState(() {
              widget.notifier.updateInventory(option['value'] as String);
            }),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildInventoryOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
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
      ),
    );
  }
}