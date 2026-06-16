// lib/presentation/screens/client/create_order_wizard/steps/step_5_area.dart
import 'package:flutter/material.dart';
import '../../../../providers/order_wizard_provider.dart';
import '../../../../../shared/widgets/custom_text_field.dart';

class Step5Area extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;
  final VoidCallback? onStateChanged;

  const Step5Area({
    super.key,
    required this.notifier,
    required this.state,
    this.onStateChanged,
  });

  @override
  State<Step5Area> createState() => _Step5AreaState();
}

class _Step5AreaState extends State<Step5Area> {
  late OrderWizardState _currentState;
  final TextEditingController _areaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
    _areaController.text = widget.state.area?.toString() ?? '';
  }

  @override
  void didUpdateWidget(Step5Area oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      setState(() {
        _currentState = widget.state;
        _areaController.text = widget.state.area?.toString() ?? '';
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
    _areaController.dispose();
    super.dispose();
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
            'Площадь помещения',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Укажите площадь в квадратных метрах',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: _areaController,
            label: 'Площадь (м²)',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.square_foot,
            onChanged: (value) {
              final area = int.tryParse(value);
              _updateState(() {
                widget.notifier.updateArea(area);
              });
            },
          ),
          const SizedBox(height: 24),
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
                    'Примерная стоимость: от ${_calculatePrice(_currentState.area)} ₸',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculatePrice(int? area) {
    if (area == null) return '0';
    final basePrice = area * 500;
    return basePrice.toString();
  }
}