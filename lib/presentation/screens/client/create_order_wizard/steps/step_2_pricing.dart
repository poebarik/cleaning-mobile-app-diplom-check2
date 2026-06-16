// lib/presentation/screens/client/create_order_wizard/steps/step_2_pricing.dart
import 'package:flutter/material.dart';
import '../../../../providers/order_wizard_provider.dart';
import '../../../../../shared/widgets/custom_text_field.dart';

class Step2Pricing extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;
  final VoidCallback? onStateChanged;

  const Step2Pricing({
    super.key,
    required this.notifier,
    required this.state,
    this.onStateChanged,
  });

  @override
  State<Step2Pricing> createState() => _Step2PricingState();
}

class _Step2PricingState extends State<Step2Pricing> {
  late OrderWizardState _currentState;
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
    _priceController.text = widget.state.fixedPrice?.toString() ?? '';
  }

  @override
  void didUpdateWidget(Step2Pricing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      setState(() {
        _currentState = widget.state;
        _priceController.text = widget.state.fixedPrice?.toString() ?? '';
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

    if (_currentState.creationType == OrderCreationType.companyAssigned) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Как определить цену?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите удобный способ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _buildPricingOption(
            context: context,
            title: 'Фиксированная цена',
            subtitle: 'Вы сами укажете сумму заказа',
            isSelected: _currentState.pricingMode == PricingMode.fixed,
            onTap: () => _updateState(() {
              widget.notifier.updatePricingMode(PricingMode.fixed);
            }),
          ),
          if (_currentState.pricingMode == PricingMode.fixed) ...[
            const SizedBox(height: 16),
            CustomTextField(
              controller: _priceController,
              label: 'Сумма заказа (₸)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.attach_money,
              onChanged: (value) {
                final price = double.tryParse(value);
                if (price != null) {
                  _updateState(() {
                    widget.notifier.updatePricingMode(PricingMode.fixed, fixedPrice: price);
                  });
                }
              },
            ),
          ],
          const SizedBox(height: 16),
          _buildPricingOption(
            context: context,
            title: 'Торг',
            subtitle: 'Специалисты предложат свои цены',
            isSelected: _currentState.pricingMode == PricingMode.bidding,
            onTap: () => _updateState(() {
              widget.notifier.updatePricingMode(PricingMode.bidding);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOption({
    required BuildContext context,
    required String title,
    required String subtitle,
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
              Radio(
                value: isSelected,
                groupValue: true,
                onChanged: (_) => onTap(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}