import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../routes/route_names.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/models/order/unified_order_request.dart';
import '../../../shared/widgets/image_uploader.dart';

class CreateCompanyOrderScreen extends ConsumerStatefulWidget {
  const CreateCompanyOrderScreen({super.key});

  @override
  ConsumerState<CreateCompanyOrderScreen> createState() => _CreateCompanyOrderScreenState();
}

class _CreateCompanyOrderScreenState extends ConsumerState<CreateCompanyOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  List<String> _uploadedImages = [];
  bool _isLoading = false;

  final List<Map<String, dynamic>> _services = [
    {'id': 1, 'name': 'Генеральная уборка', 'price': 5000},
    {'id': 2, 'name': 'Поддерживающая уборка', 'price': 3000},
    {'id': 3, 'name': 'Уборка после ремонта', 'price': 8000},
    {'id': 4, 'name': 'Мойка окон', 'price': 2000},
    {'id': 5, 'name': 'Химчистка мебели', 'price': 6000},
  ];
  int? _selectedServiceId;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _createOrder() async {
    if (_formKey.currentState!.validate() && _selectedServiceId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final orderRequest = UnifiedOrderRequest(
          serviceId: _selectedServiceId!,
          address: _addressController.text,
          orderDate: DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          ),
          description: _descriptionController.text,
          // ✅ ИСПРАВЛЕНО: используем COMPANY_ASSIGNED вместо COMPANY
          fulfillmentType: 'COMPANY_ASSIGNED',
          imageObjectNames: _uploadedImages.isNotEmpty ? _uploadedImages : null,
        );

        final repository = OrderRepository();
        await repository.createOrderWithMode(orderRequest);

        if (mounted) {
          CustomSnackbar.showSuccess(context, 'Заказ успешно создан!');
          context.go(RouteNames.myOrders);
        }
      } catch (e) {
        if (mounted) {
          CustomSnackbar.showError(context, 'Ошибка: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заказ через компанию'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Выберите услугу',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._services.map((service) => RadioListTile<int>(
                title: Text(service['name']),
                subtitle: Text('${service['price']} ₽'),
                value: service['id'],
                groupValue: _selectedServiceId,
                onChanged: (value) {
                  setState(() {
                    _selectedServiceId = value;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
                contentPadding: EdgeInsets.zero,
              )),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _addressController,
                label: 'Адрес',
                prefixIcon: Icons.location_on_outlined,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Дата', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text('${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).inputDecorationTheme.fillColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Время', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(_selectedTime.format(context)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Описание',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              const Text('Фото (необязательно)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ImageUploader(
                onImagesUploaded: (objectNames) {
                  setState(() {
                    _uploadedImages = objectNames;
                  });
                },
                folder: 'orders',
                maxImages: 5,
              ),
              const SizedBox(height: 32),
              CustomButton(
                onPressed: _createOrder,
                text: 'Создать заказ',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}