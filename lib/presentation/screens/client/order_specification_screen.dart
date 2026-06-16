import 'package:flutter/material.dart';
import '../../../data/models/order/order_specification_dto.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class OrderSpecificationScreen extends StatefulWidget {
  final Function(OrderSpecificationDTO) onSpecificationComplete;

  const OrderSpecificationScreen({
    super.key,
    required this.onSpecificationComplete,
  });

  @override
  State<OrderSpecificationScreen> createState() => _OrderSpecificationScreenState();
}

class _OrderSpecificationScreenState extends State<OrderSpecificationScreen> {
  // ==================== 1. ЛОКАЦИЯ ====================
  String? _locationType;
  final _locationCustomController = TextEditingController();
  bool _showLocationCustom = false;

  final List<Map<String, dynamic>> _locationTypes = [
    {'value': 'APARTMENT', 'label': 'Квартира', 'icon': Icons.apartment},
    {'value': 'HOUSE', 'label': 'Дом', 'icon': Icons.house},
    {'value': 'OFFICE', 'label': 'Офис', 'icon': Icons.business},
    {'value': 'COMMERCIAL', 'label': 'Коммерческое помещение', 'icon': Icons.storefront},
    {'value': 'CUSTOM', 'label': 'Другое', 'icon': Icons.edit},
  ];

  // ==================== 2. ТИП УБОРКИ ====================
  String? _cleaningType;

  final List<Map<String, dynamic>> _cleaningTypes = [
    {'value': 'MAINTENANCE', 'label': 'Поддерживающая', 'icon': Icons.cleaning_services, 'description': 'Регулярная уборка для поддержания чистоты'},
    {'value': 'DEEP_CLEANING', 'label': 'Генеральная', 'icon': Icons.cleaning_services, 'description': 'Полная уборка всех поверхностей'},
    {'value': 'AFTER_RENOVATION', 'label': 'После ремонта', 'icon': Icons.construction, 'description': 'Удаление строительной пыли и мусора'},
    {'value': 'MOVE_IN', 'label': 'Перед заселением', 'icon': Icons.moving, 'description': 'Уборка перед въездом'},
    {'value': 'MOVE_OUT', 'label': 'После выезда', 'icon': Icons.logout, 'description': 'Уборка после выезда'},
    {'value': 'CUSTOM', 'label': 'Другое', 'icon': Icons.edit, 'description': 'Укажите свой вариант'},
  ];

  // ==================== 3. ПЛОЩАДЬ ====================
  final _areaController = TextEditingController();

  // ==================== 4. КОМНАТЫ ====================
  List<String> _selectedRooms = [];
  final _roomsCustomController = TextEditingController();
  bool _showRoomsCustom = false;

  final List<Map<String, dynamic>> _roomOptions = [
    {'value': 'ENTIRE', 'label': 'Вся квартира', 'icon': Icons.home},
    {'value': 'KITCHEN', 'label': 'Кухня', 'icon': Icons.kitchen},
    {'value': 'BATHROOM', 'label': 'Санузел', 'icon': Icons.bathtub},
    {'value': 'BALCONY', 'label': 'Балкон', 'icon': Icons.balcony},
    {'value': 'BEDROOM', 'label': 'Спальня', 'icon': Icons.bed},
    {'value': 'LIVING_ROOM', 'label': 'Гостиная', 'icon': Icons.living},
    {'value': 'CUSTOM', 'label': 'Свой вариант', 'icon': Icons.edit},
  ];

  // ==================== 5. ДОПОЛНИТЕЛЬНЫЕ УСЛУГИ ====================
  List<String> _selectedServices = [];
  final _customServicesController = TextEditingController();
  List<String> _customServicesList = [];

  final List<Map<String, dynamic>> _serviceOptions = [
    {'value': 'WINDOWS', 'label': 'Мытьё окон', 'icon': Icons.window, 'price': 2000},
    {'value': 'FRIDGE', 'label': 'Мытьё холодильника', 'icon': Icons.kitchen, 'price': 1000},
    {'value': 'OVEN', 'label': 'Мытьё духовки', 'icon': Icons.microwave, 'price': 1000},
    {'value': 'FURNITURE', 'label': 'Химчистка мебели', 'icon': Icons.weekend, 'price': 3000},
    {'value': 'IRONING', 'label': 'Глажка белья', 'icon': Icons.iron, 'price': 1500},
  ];

  // ==================== 6. ИНВЕНТАРЬ ====================
  String? _inventory;

  final List<Map<String, dynamic>> _inventoryOptions = [
    {'value': 'CLIENT', 'label': 'Да (мой)', 'icon': Icons.person, 'description': 'У меня есть все необходимое'},
    {'value': 'CLEANER', 'label': 'Нет (нужен клинера)', 'icon': Icons.cleaning_services, 'description': 'Инвентарь предоставит клинер'},
    {'value': 'PARTIAL', 'label': 'Частично', 'icon': Icons.share, 'description': 'Что-то есть, что-то нужно'},
  ];

  // ==================== 7. ЦЕНООБРАЗОВАНИЕ ====================
  String? _pricingMode;
  final _priceController = TextEditingController();
  final _maxPriceController = TextEditingController();

  // ==================== 8. ДОПОЛНИТЕЛЬНО ====================
  final _roomsCountController = TextEditingController();
  final _bathroomsController = TextEditingController();
  bool? _hasPets;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _locationCustomController.dispose();
    _areaController.dispose();
    _roomsCustomController.dispose();
    _customServicesController.dispose();
    _priceController.dispose();
    _maxPriceController.dispose();
    _roomsCountController.dispose();
    _bathroomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addCustomService() {
    final service = _customServicesController.text.trim();
    if (service.isNotEmpty && !_customServicesList.contains(service)) {
      setState(() {
        _customServicesList.add(service);
        _customServicesController.clear();
      });
    }
  }

  void _removeCustomService(int index) {
    setState(() {
      _customServicesList.removeAt(index);
    });
  }

  void _saveAndContinue() {
    final specification = OrderSpecificationDTO(
      // 1. Локация
      locationType: _locationType,
      locationCustom: _locationType == 'CUSTOM' ? _locationCustomController.text : null,

      // 2. Тип уборки
      cleaningType: _cleaningType,

      // 3. Площадь
      area: _areaController.text.isNotEmpty ? int.tryParse(_areaController.text) : null,

      // 4. Комнаты
      rooms: _selectedRooms.isNotEmpty
          ? (_selectedRooms.contains('CUSTOM')
          ? ['CUSTOM']
          : _selectedRooms)
          : null,
      roomsCustom: _selectedRooms.contains('CUSTOM') ? _roomsCustomController.text : null,

      // 5. Дополнительные услуги
      additionalServices: _selectedServices.isNotEmpty ? _selectedServices : null,
      customServices: _customServicesList.isNotEmpty ? _customServicesList : null,

      // 6. Инвентарь
      inventory: _inventory,

      // 7. Ценообразование
      pricingMode: _pricingMode,
      price: _pricingMode == 'FIXED' ? double.tryParse(_priceController.text) : null,
      maxPrice: _pricingMode == 'BIDDING' ? double.tryParse(_maxPriceController.text) : null,

      // 8. Дополнительно
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      roomsCount: _roomsCountController.text.isNotEmpty ? int.tryParse(_roomsCountController.text) : null,
      bathrooms: _bathroomsController.text.isNotEmpty ? int.tryParse(_bathroomsController.text) : null,
      hasPets: _hasPets,
    );

    widget.onSpecificationComplete(specification);
  }

  bool get _isValid {
    return _locationType != null &&
        _cleaningType != null &&
        _pricingMode != null &&
        (_pricingMode != 'FIXED' || (_priceController.text.isNotEmpty && double.tryParse(_priceController.text) != null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали уборки'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==================== 1. ЛОКАЦИЯ ====================
            _buildSectionCard(
              title: 'Где провести уборку?',
              icon: Icons.location_city,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _locationTypes.map((type) {
                      final isSelected = _locationType == type['value'];
                      return _buildSelectionCard(
                        label: type['label'],
                        icon: type['icon'],
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _locationType = type['value'];
                            _showLocationCustom = type['value'] == 'CUSTOM';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (_showLocationCustom) ...[
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _locationCustomController,
                      label: 'Укажите тип помещения',
                      prefixIcon: Icons.edit,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================== 2. ТИП УБОРКИ ====================
            _buildSectionCard(
              title: 'Какая уборка нужна?',
              icon: Icons.cleaning_services,
              content: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _cleaningTypes.map((type) {
                  final isSelected = _cleaningType == type['value'];
                  return _buildSelectionCard(
                    label: type['label'],
                    icon: type['icon'],
                    isSelected: isSelected,
                    subtitle: type['description'],
                    onTap: () => setState(() => _cleaningType = type['value']),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================== 3. ПЛОЩАДЬ ====================
            _buildSectionCard(
              title: 'Общая площадь',
              icon: Icons.square_foot,
              content: CustomTextField(
                controller: _areaController,
                label: 'Площадь (м²)',
                prefixIcon: Icons.square_foot,
                keyboardType: TextInputType.number,
                suffixText: 'м²',
              ),
            ),

            const SizedBox(height: 16),

            // ==================== 4. КОМНАТЫ ====================
            _buildSectionCard(
              title: 'Что нужно убрать?',
              icon: Icons.home,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _roomOptions.map((room) {
                      final isSelected = _selectedRooms.contains(room['value']);
                      return FilterChip(
                        label: Text(room['label']),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedRooms.add(room['value']);
                            } else {
                              _selectedRooms.remove(room['value']);
                            }
                            _showRoomsCustom = _selectedRooms.contains('CUSTOM');
                          });
                        },
                        avatar: Icon(room['icon'], size: 18),
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        checkmarkColor: Theme.of(context).primaryColor,
                      );
                    }).toList(),
                  ),
                  if (_showRoomsCustom) ...[
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _roomsCustomController,
                      label: 'Укажите помещения',
                      prefixIcon: Icons.edit,
                      hint: 'Например: Подвал, гараж, кладовка',
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _roomsCountController,
                          label: 'Количество комнат',
                          prefixIcon: Icons.home,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomTextField(
                          controller: _bathroomsController,
                          label: 'Количество санузлов',
                          prefixIcon: Icons.bathtub,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================== 5. ДОПОЛНИТЕЛЬНЫЕ УСЛУГИ ====================
            _buildSectionCard(
              title: 'Дополнительные услуги',
              icon: Icons.more_horiz,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _serviceOptions.map((service) {
                      final isSelected = _selectedServices.contains(service['value']);
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(service['label']),
                            const SizedBox(width: 4),
                            Text(
                              '+${service['price']} ₽',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedServices.add(service['value']);
                            } else {
                              _selectedServices.remove(service['value']);
                            }
                          });
                        },
                        avatar: Icon(service['icon'], size: 18),
                        selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Свои услуги',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _customServicesController,
                          label: 'Услуга',
                          prefixIcon: Icons.add_circle,
                          hint: 'Например: Помыть люстру',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addCustomService,
                        icon: const Icon(Icons.add),
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                  if (_customServicesList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _customServicesList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final service = entry.value;
                        return Chip(
                          label: Text(service),
                          onDeleted: () => _removeCustomService(index),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          backgroundColor: Colors.grey.shade100,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================== 6. ИНВЕНТАРЬ ====================
            _buildSectionCard(
              title: 'Есть ли инвентарь?',
              icon: Icons.inventory,
              content: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _inventoryOptions.map((option) {
                  final isSelected = _inventory == option['value'];
                  return _buildSelectionCard(
                    label: option['label'],
                    icon: option['icon'],
                    isSelected: isSelected,
                    subtitle: option['description'],
                    onTap: () => setState(() => _inventory = option['value']),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================== 7. ЦЕНООБРАЗОВАНИЕ ====================
            _buildSectionCard(
              title: 'Как формируется цена?',
              icon: Icons.attach_money,
              content: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriceCard(
                          'FIXED',
                          'Я ставлю цену',
                          Icons.attach_money,
                          _pricingMode == 'FIXED',
                          description: 'Вы устанавливаете фиксированную цену',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPriceCard(
                          'BIDDING',
                          'Клинеры предлагают',
                          Icons.swap_horiz,
                          _pricingMode == 'BIDDING',
                          description: 'Клинеры сами предложат цену',
                        ),
                      ),
                    ],
                  ),
                  if (_pricingMode == 'FIXED') ...[
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _priceController,
                      label: 'Ваша цена (₽)',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  if (_pricingMode == 'BIDDING') ...[
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: _maxPriceController,
                      label: 'Максимальная цена (₽)',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      hint: 'Клинеры не смогут предложить цену выше этой',
                      helperText: 'Очень полезная функция, чтобы не переплачивать',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================== 8. ДОПОЛНИТЕЛЬНО ====================
            _buildSectionCard(
              title: 'Дополнительная информация',
              icon: Icons.note,
              content: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildYesNoCard(
                          'Есть животные',
                          Icons.pets,
                          _hasPets == true,
                              () => setState(() => _hasPets = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildYesNoCard(
                          'Нет животных',
                          Icons.pets_outlined,
                          _hasPets == false,
                              () => setState(() => _hasPets = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _notesController,
                    label: 'Комментарий',
                    prefixIcon: Icons.comment,
                    maxLines: 3,
                    hint: 'Например: Есть кот. Использовать гипоаллергенные средства.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ==================== КНОПКА СОХРАНЕНИЯ ====================
            CustomButton(
              onPressed: _isValid ? _saveAndContinue : null,
              text: 'Сохранить детали',
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(String value, String label, IconData icon, bool isSelected, {String? description}) {
    return GestureDetector(
      onTap: () => setState(() => _pricingMode = value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoCard(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}