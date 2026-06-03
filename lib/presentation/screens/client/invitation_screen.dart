import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../shared/widgets/image_uploader.dart';
import '../../../core/utils/validators.dart';
import '../../../routes/route_names.dart';
import '../../providers/invitation_provider.dart';

class InvitationScreen extends ConsumerStatefulWidget {
  final int orderId;
  final int cleanerId;
  final String? cleanerName;
  final double? cleanerRating;

  const InvitationScreen({
    super.key,
    required this.orderId,
    required this.cleanerId,
    this.cleanerName,
    this.cleanerRating,
  });

  @override
  ConsumerState<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends ConsumerState<InvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _commentController = TextEditingController();
  List<String> _uploadedImages = [];

  @override
  void dispose() {
    _priceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      'orderId': widget.orderId,
      'cleanerId': widget.cleanerId,
      'proposedPrice': double.parse(_priceController.text),
      'comment': _commentController.text,
      if (_uploadedImages.isNotEmpty) 'imageObjectNames': _uploadedImages,
    };

    await ref.read(invitationProvider.notifier).createInvitation(data);

    final state = ref.read(invitationProvider);
    if (state.isCreated) {
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Приглашение отправлено!');
        context.go(RouteNames.myOrders);
      }
    } else if (state.error != null && mounted) {
      CustomSnackbar.showError(context, state.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitationState = ref.watch(invitationProvider);
    final isLoading = invitationState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пригласить клинера'),
        elevation: 0,
      ),
      body: SingleChildScrollView(  // ✅ Исправлено: SingleChildScrollView, а не SingleChildScrollPath
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Клинер',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.cleanerName ?? 'Клинер',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.cleanerRating != null)
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(widget.cleanerRating!.toStringAsFixed(1)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _priceController,
                label: 'Предлагаемая цена (₽)',
                prefixIcon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _commentController,
                label: 'Комментарий',
                prefixIcon: Icons.message_outlined,
                maxLines: 3,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),
              const Text(
                'Фото (необязательно)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ImageUploader(
                onImagesUploaded: (objectNames) {
                  setState(() {
                    _uploadedImages = objectNames;
                  });
                },
                folder: 'invitations',
                maxImages: 5,
              ),
              const SizedBox(height: 24),
              CustomButton(
                onPressed: _sendInvitation,
                text: 'Отправить приглашение',
                isLoading: isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}