// lib/presentation/screens/client/create_order_wizard/steps/step_1_preferences.dart
import 'package:flutter/material.dart';
import '../../../../providers/order_wizard_provider.dart';

class Step1Preferences extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;

  const Step1Preferences({
    super.key,
    required this.notifier,
    required this.state,
  });

  @override
  State<Step1Preferences> createState() => _Step1PreferencesState();
}

class _Step1PreferencesState extends State<Step1Preferences> {
  late OrderWizardState _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
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
            'Как вы хотите получить предложения?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите способ поиска специалиста',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          _buildOption(
            context: context,
            icon: Icons.format_list_numbered,
            title: 'До 6 предложений специалистов',
            subtitle: 'Специалисты предложат свои цены, вы выберете лучший вариант',
            isSelected: _currentState.creationType == OrderCreationType.limitedBids,
            onTap: () {
              setState(() {
                widget.notifier.updateCreationType(OrderCreationType.limitedBids);
                _currentState = widget.notifier.state;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildOption(
            context: context,
            icon: Icons.public,
            title: 'Открытый рынок',
            subtitle: 'Просматривайте всех специалистов и их предложения',
            isSelected: _currentState.creationType == OrderCreationType.openMarket,
            onTap: () {
              setState(() {
                widget.notifier.updateCreationType(OrderCreationType.openMarket);
                _currentState = widget.notifier.state;
              });
            },
          ),
          const SizedBox(height: 16),
          _buildOption(
            context: context,
            icon: Icons.business,
            title: 'Выбрать компанию',
            subtitle: 'Компания сама назначит специалиста',
            isSelected: _currentState.creationType == OrderCreationType.companyAssigned,
            onTap: () {
              setState(() {
                widget.notifier.updateCreationType(OrderCreationType.companyAssigned);
                _currentState = widget.notifier.state;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required IconData icon,
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