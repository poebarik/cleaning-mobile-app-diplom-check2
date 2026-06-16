// lib/presentation/screens/client/create_order_wizard/steps/step_3_location.dart
import 'package:flutter/material.dart';
import '../../../../providers/order_wizard_provider.dart';
import '../../../../../shared/widgets/custom_text_field.dart';

class Step3Location extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;
  final VoidCallback? onStateChanged;

  const Step3Location({
    super.key,
    required this.notifier,
    required this.state,
    this.onStateChanged,
  });

  @override
  State<Step3Location> createState() => _Step3LocationState();
}

class _Step3LocationState extends State<Step3Location> {
  late OrderWizardState _currentState;
  final TextEditingController _customController = TextEditingController();

  final Map<String, Map<String, dynamic>> _locationTypes = const {
    'APARTMENT': {'icon': Icons.apartment, 'label': 'Квартира'},
    'HOUSE': {'icon': Icons.house, 'label': 'Дом'},
    'OFFICE': {'icon': Icons.business, 'label': 'Офис'},
    'COMMERCIAL': {'icon': Icons.store, 'label': 'Коммерческое помещение'},
    'CUSTOM': {'icon': Icons.edit, 'label': 'Другое'},
  };

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
    _customController.text = widget.state.locationCustom ?? '';
  }

  @override
  void didUpdateWidget(Step3Location oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      setState(() {
        _currentState = widget.state;
        _customController.text = widget.state.locationCustom ?? '';
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
    _customController.dispose();
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
            'Где провести уборку?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите тип помещения',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _locationTypes.length,
            itemBuilder: (context, index) {
              final key = _locationTypes.keys.elementAt(index);
              final type = _locationTypes[key]!;
              final isSelected = _currentState.locationType == key;

              return _buildLocationCard(
                context: context,
                icon: type['icon'],
                label: type['label'],
                isSelected: isSelected,
                onTap: () => _updateState(() {
                  widget.notifier.updateLocationType(key);
                  if (key != 'CUSTOM') {
                    // Исправлено: передаем пустую строку вместо null
                    widget.notifier.updateLocationCustom('');
                  }
                }),
              );
            },
          ),
          if (_currentState.locationType == 'CUSTOM') ...[
            const SizedBox(height: 24),
            CustomTextField(
              controller: _customController,
              label: 'Укажите тип помещения',
              hint: 'Например: Склад, Гараж, Студия...',
              prefixIcon: Icons.edit_note,
              onChanged: (value) {
                _updateState(() {
                  if (value.isNotEmpty) {
                    widget.notifier.updateLocationCustom(value);
                  }
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationCard({
    required BuildContext context,
    required IconData icon,
    required String label,
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.check_circle,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}