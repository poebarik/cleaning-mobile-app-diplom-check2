// lib/presentation/screens/client/create_order_wizard/steps/step_7_services.dart
import 'package:flutter/material.dart';
import '../../../../providers/order_wizard_provider.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_button.dart';

class Step7Services extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;
  final VoidCallback? onStateChanged;

  const Step7Services({
    super.key,
    required this.notifier,
    required this.state,
    this.onStateChanged,
  });

  @override
  State<Step7Services> createState() => _Step7ServicesState();
}

class _Step7ServicesState extends State<Step7Services> {
  late OrderWizardState _currentState;
  final TextEditingController _customServiceController = TextEditingController();
  bool _showAddCustom = false;

  final List<Map<String, dynamic>> _availableServices = const [
    {'value': 'WINDOWS', 'icon': Icons.window, 'label': 'Мытьё окон', 'price': '+2 000 ₸'},
    {'value': 'FRIDGE', 'icon': Icons.kitchen, 'label': 'Мытьё холодильника', 'price': '+1 500 ₸'},
    {'value': 'OVEN', 'icon': Icons.microwave, 'label': 'Чистка духовки', 'price': '+1 500 ₸'},
    {'value': 'FURNITURE_CLEANING', 'icon': Icons.chair, 'label': 'Чистка мебели', 'price': '+3 000 ₸'},
    {'value': 'IRONING', 'icon': Icons.iron, 'label': 'Глажка белья', 'price': '+2 000 ₸'},
  ];

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
  }

  @override
  void didUpdateWidget(Step7Services oldWidget) {
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
  void dispose() {
    _customServiceController.dispose();
    super.dispose();
  }

  void _addCustomService() {
    final service = _customServiceController.text.trim();
    if (service.isNotEmpty) {
      _updateState(() {
        widget.notifier.addCustomService(service);
      });
      _customServiceController.clear();
      setState(() => _showAddCustom = false);
    }
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
            'Дополнительные услуги',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите дополнительные услуги',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ..._availableServices.map((service) => _buildServiceTile(
            context: context,
            icon: service['icon'] as IconData,
            label: service['label'] as String,
            price: service['price'] as String,
            isSelected: _currentState.additionalServices.contains(service['value']),
            onTap: () => _updateState(() {
              widget.notifier.toggleAdditionalService(service['value'] as String);
            }),
          )),
          if (_currentState.customServices.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ваши услуги:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _currentState.customServices.map((service) => Chip(
                      label: Text(service),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => _updateState(() {
                        widget.notifier.removeCustomService(service);
                      }),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (!_showAddCustom)
            CustomButton(
              onPressed: () => setState(() => _showAddCustom = true),
              text: '+ Добавить свою услугу',
              isOutlined: true,
            ),
          if (_showAddCustom) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _customServiceController,
                    label: 'Название услуги',
                    hint: 'Например: Мытьё посуды',
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _addCustomService,
                  icon: const Icon(Icons.add_circle),
                  color: theme.colorScheme.primary,
                  iconSize: 48,
                ),
                IconButton(
                  onPressed: () => setState(() => _showAddCustom = false),
                  icon: const Icon(Icons.cancel),
                  color: theme.colorScheme.error,
                  iconSize: 48,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String price,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => onTap(),
        secondary: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label),
        subtitle: Text(price, style: theme.textTheme.bodySmall),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}