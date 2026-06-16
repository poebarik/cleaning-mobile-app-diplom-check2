// lib/presentation/screens/client/create_order_wizard/steps/step_10_notes.dart
import 'package:flutter/material.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../providers/order_wizard_provider.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/image_uploader.dart';

class Step10Notes extends StatefulWidget {
  final OrderWizardNotifier notifier;
  final OrderWizardState state;
  final VoidCallback? onStateChanged;

  const Step10Notes({
    super.key,
    required this.notifier,
    required this.state,
    this.onStateChanged,
  });

  @override
  State<Step10Notes> createState() => _Step10NotesState();
}

class _Step10NotesState extends State<Step10Notes> {
  late OrderWizardState _currentState;
  final TextEditingController _notesController = TextEditingController();
  List<String> _uploadedImages = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentState = widget.state;
    _notesController.text = widget.state.notes ?? '';
    _uploadedImages = List<String>.from(widget.state.imageObjectNames ?? []);
  }

  @override
  void didUpdateWidget(Step10Notes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      setState(() {
        _currentState = widget.state;
        _notesController.text = widget.state.notes ?? '';
        _uploadedImages = List<String>.from(widget.state.imageObjectNames ?? []);
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
    _notesController.dispose();
    super.dispose();
  }

  void _onImagesUploaded(List<String> objectNames) {
    setState(() {
      _uploadedImages = [..._uploadedImages, ...objectNames];
      _isUploading = false;
    });
    _updateState(() {
      widget.notifier.updateImages(_uploadedImages);
    });
  }

  void _onUploadStarted() {
    setState(() {
      _isUploading = true;
    });
  }

  void _removeImage(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
    _updateState(() {
      widget.notifier.updateImages(_uploadedImages);
    });
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
            'Дополнительная информация',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Расскажите о своих пожеланиях и добавьте фото',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),

          CustomTextField(
            controller: _notesController,
            label: 'Заметки',
            hint: 'Например: есть животные, нужен парковочный пропуск, особые требования...',
            maxLines: 5,
            onChanged: (value) {
              _updateState(() {
                widget.notifier.updateNotes(value);
              });
            },
          ),
          const SizedBox(height: 24),

          const Text(
            'Фотографии помещения',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'необязательно',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 12),

          if (_uploadedImages.isNotEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _uploadedImages.length,
                itemBuilder: (context, index) {
                  final imageUrl = '${ApiConstants.baseUrl}/files/${_uploadedImages[index]}';
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.background,
                              child: const Icon(Icons.broken_image, size: 40, color: AppColors.textHint),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (!_isUploading)
            ImageUploader(
              onImagesUploaded: _onImagesUploaded,
              folder: 'order_notes',
              maxImages: 5 - _uploadedImages.length,
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),

          const SizedBox(height: 24),

          _buildSummaryCard(context, _currentState),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              onPressed: () {
                _updateState(() {
                  widget.notifier.updateNotes(_notesController.text);
                  widget.notifier.updateImages(_uploadedImages);
                });
                Navigator.pop(context);
              },
              text: 'Готово',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, OrderWizardState state) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primaryContainer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Краткое резюме заказа',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            context: context,
            icon: Icons.location_on,
            label: 'Адрес',
            value: state.address.isNotEmpty ? state.address : 'Не указан',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context: context,
            icon: Icons.calendar_today,
            label: 'Дата',
            value: _formatDate(state.orderDate),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context: context,
            icon: Icons.access_time,
            label: 'Время',
            value: _formatTime(state.orderDate),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context: context,
            icon: Icons.settings,
            label: 'Тип заказа',
            value: _getCreationTypeText(state.creationType),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context: context,
            icon: Icons.price_change,
            label: 'Ценообразование',
            value: _getPricingText(state),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            context: context,
            icon: Icons.cleaning_services,
            label: 'Тип уборки',
            value: _getCleaningTypeText(state.cleaningType),
          ),
          if (state.area != null) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              context: context,
              icon: Icons.square_foot,
              label: 'Площадь',
              value: '${state.area} м²',
            ),
          ],
          if (_uploadedImages.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              context: context,
              icon: Icons.photo,
              label: 'Фото',
              value: '${_uploadedImages.length} шт.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getCreationTypeText(OrderCreationType? type) {
    switch (type) {
      case OrderCreationType.limitedBids:
        return 'До 6 предложений';
      case OrderCreationType.openMarket:
        return 'Открытый рынок';
      case OrderCreationType.companyAssigned:
        return 'Выбор компании';
      default:
        return 'Не выбран';
    }
  }

  String _getPricingText(OrderWizardState state) {
    if (state.pricingMode == PricingMode.fixed) {
      return 'Фиксированная: ${state.fixedPrice?.toInt()} ₸';
    } else if (state.pricingMode == PricingMode.bidding) {
      return 'Торг${state.maxPrice != null ? ' (до ${state.maxPrice!.toInt()} ₸)' : ''}';
    }
    return 'Не выбран';
  }

  String _getCleaningTypeText(String type) {
    switch (type) {
      case 'MAINTENANCE':
        return 'Поддерживающая';
      case 'DEEP_CLEANING':
        return 'Генеральная';
      case 'AFTER_RENOVATION':
        return 'После ремонта';
      case 'MOVE_IN':
        return 'Перед заселением';
      case 'MOVE_OUT':
        return 'После выезда';
      default:
        return type;
    }
  }
}