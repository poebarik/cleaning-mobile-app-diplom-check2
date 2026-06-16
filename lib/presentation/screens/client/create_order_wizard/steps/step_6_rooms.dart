// lib/presentation/screens/client/create_order_wizard/steps/step_6_rooms.dart
import 'package:flutter/material.dart';
import '../../../../providers/order_wizard_provider.dart';
import '../../../../../shared/widgets/custom_text_field.dart';

class Step6Rooms extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;
  final VoidCallback? onStateChanged;

  const Step6Rooms({
    super.key,
    required this.notifier,
    required this.state,
    this.onStateChanged,
  });

  @override
  State<Step6Rooms> createState() => _Step6RoomsState();
}

class _Step6RoomsState extends State<Step6Rooms> {
  late OrderWizardState _currentState;
  final TextEditingController _customController = TextEditingController();
  bool _showCustomInput = false;

  final List<Map<String, dynamic>> _roomOptions = const [
    {'value': 'KITCHEN', 'icon': Icons.kitchen, 'label': 'Кухня'},
    {'value': 'BATHROOM', 'icon': Icons.bathroom, 'label': 'Ванная'},
    {'value': 'BALCONY', 'icon': Icons.balcony, 'label': 'Балкон'},
    {'value': 'BEDROOM', 'icon': Icons.bed, 'label': 'Спальня'},
    {'value': 'LIVING_ROOM', 'icon': Icons.living, 'label': 'Гостиная'},
  ];

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
    _customController.text = widget.state.roomsCustom ?? '';
    _showCustomInput = widget.state.rooms.contains('CUSTOM');
  }

  @override
  void didUpdateWidget(Step6Rooms oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      setState(() {
        _currentState = widget.state;
        _customController.text = widget.state.roomsCustom ?? '';
        _showCustomInput = widget.state.rooms.contains('CUSTOM');
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
        mainAxisSize: MainAxisSize.min, // ✅ Добавлено
        children: [
          Text(
            'Какие комнаты нужно убрать?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите все необходимые комнаты',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          // ✅ Обернули Wrap в ConstrainedBox для ограничения высоты
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ..._roomOptions.map((room) => _buildRoomChip(
                  context: context,
                  label: room['label'] as String,
                  icon: room['icon'] as IconData,
                  isSelected: _currentState.rooms.contains(room['value']),
                  onTap: () => _updateState(() {
                    widget.notifier.toggleRoom(room['value'] as String);
                  }),
                )),
                _buildRoomChip(
                  context: context,
                  label: 'Другое',
                  icon: Icons.edit,
                  isSelected: _currentState.rooms.contains('CUSTOM'),
                  onTap: () => _updateState(() {
                    widget.notifier.toggleRoom('CUSTOM');
                    setState(() => _showCustomInput = !_showCustomInput);
                    if (!_currentState.rooms.contains('CUSTOM')) {
                      widget.notifier.updateRoomsCustom('');
                    }
                  }),
                ),
              ],
            ),
          ),
          if (_currentState.rooms.contains('CUSTOM') || _showCustomInput) ...[
            const SizedBox(height: 24),
            CustomTextField(
              controller: _customController,
              label: 'Укажите комнаты',
              hint: 'Например: Кладовая, Гардеробная...',
              prefixIcon: Icons.edit_note,
              onChanged: (value) {
                _updateState(() {
                  widget.notifier.updateRoomsCustom(value);
                });
              },
            ),
          ],
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Выбрано комнат: ${_currentState.rooms.length}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 14, // ✅ Добавлен фиксированный размер
        color: isSelected ? theme.colorScheme.onPrimary : null,
      ),
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? theme.colorScheme.onPrimary : null,
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary,
      side: BorderSide(
        color: isSelected ? Colors.transparent : theme.colorScheme.outline,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // ✅ Добавлен padding
    );
  }
}