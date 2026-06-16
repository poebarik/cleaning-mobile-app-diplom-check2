// lib/presentation/screens/client/create_order_wizard/steps/step_9_price_limit.dart
import 'package:flutter/material.dart';
import '../../../../providers/order_wizard_provider.dart';
import '../../../../../shared/widgets/custom_text_field.dart';

class Step9PriceLimit extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;
  final VoidCallback? onStateChanged;

  const Step9PriceLimit({
    super.key,
    required this.notifier,
    required this.state,
    this.onStateChanged,
  });

  @override
  State<Step9PriceLimit> createState() => _Step9PriceLimitState();
}

class _Step9PriceLimitState extends State<Step9PriceLimit> {
  late OrderWizardState _currentState;
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
    _priceController.text = widget.state.maxPrice?.toString() ?? '';
  }

  @override
  void didUpdateWidget(Step9PriceLimit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      setState(() {
        _currentState = widget.state;
        _priceController.text = widget.state.maxPrice?.toString() ?? '';
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
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Показываем только для режима торгов
    if (_currentState.pricingMode != PricingMode.bidding) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Максимальная цена',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Укажите максимальную сумму, которую готовы заплатить',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          CustomTextField(
            controller: _priceController,
            label: 'Максимальная цена (₸)',
            keyboardType: TextInputType.number,
            prefixIcon: Icons.attach_money,
            onChanged: (value) {
              final price = double.tryParse(value);
              _updateState(() {
                widget.notifier.updateMaxPrice(price);
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
                    'Специалисты будут предлагать цены в рамках вашего бюджета',
                    style: theme.textTheme.bodySmall,
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