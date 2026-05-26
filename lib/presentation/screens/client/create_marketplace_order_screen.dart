import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../routes/route_names.dart';
import '../../../data/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class CreateMarketplaceOrderScreen extends ConsumerStatefulWidget {
  const CreateMarketplaceOrderScreen({super.key});

  @override
  ConsumerState<CreateMarketplaceOrderScreen> createState() => _CreateMarketplaceOrderScreenState();
}

class _CreateMarketplaceOrderScreenState extends ConsumerState<CreateMarketplaceOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _deadlineDaysController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _services = [
    {'id': 1, 'name': 'Генеральная уборка'},
    {'id': 2, 'name': 'Поддерживающая уборка'},
    {'id': 3, 'name': 'Уборка после ремонта'},
    {'id': 4, 'name': 'Мойка окон'},
    {'id': 5, 'name': 'Химчистка мебели'},
  ];
  int? _selectedServiceId;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
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

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate() && _selectedServiceId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final orderData = {
          'serviceId': _selectedServiceId,
          'address': _addressController.text,
          'orderDate': DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          ).toIso8601String(),
          'description': _descriptionController.text,
          'budget': double.parse(_budgetController.text),
          'responseDeadlineDays': int.parse(_deadlineDaysController.text),
        };

        final dio = DioClient.instance;
        final response = await dio.post(
          '${ApiConstants.baseUrl}${ApiConstants.marketplaceOrders}',
          data: orderData,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (context.mounted) {
            CustomSnackbar.showSuccess(context, 'Объявление опубликовано! Клинеры скоро откликнутся.');
            context.go(RouteNames.myOrders);
          }
        } else {
          throw Exception('Ошибка создания объявления');
        }
      } catch (e) {
        if (context.mounted) {
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
        title: const Text('Опубликовать объявление'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Клинеры увидят ваше объявление и предложат свою цену',
                        style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Выберите услугу',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ..._services.map((service) => RadioListTile<int>(
                title: Text(service['name']),
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
                controller: _budgetController,
                label: 'Бюджет (Т)',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _deadlineDaysController,
                label: 'Срок отклика (дней)',
                prefixIcon: Icons.timer_outlined,
                keyboardType: TextInputType.number,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                label: 'Описание',
                prefixIcon: Icons.description_outlined,
                maxLines: 4,
                validator: Validators.required,
              ),
              const SizedBox(height: 32),
              CustomButton(
                onPressed: _handleSubmit,
                text: 'Опубликовать объявление',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}