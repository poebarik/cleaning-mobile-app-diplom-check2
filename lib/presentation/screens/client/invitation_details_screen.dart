import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../domain/enums/order_action.dart';
import '../../../data/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/invitation/cleaner_invitation.dart';
import '../../providers/auth_provider.dart';

class InvitationDetailsScreen extends ConsumerStatefulWidget {
  final int invitationId;
  final String userRole; // 'CLIENT' or 'CLEANER'

  const InvitationDetailsScreen({
    super.key,
    required this.invitationId,
    required this.userRole,
  });

  @override
  ConsumerState<InvitationDetailsScreen> createState() => _InvitationDetailsScreenState();
}

class _InvitationDetailsScreenState extends ConsumerState<InvitationDetailsScreen> {
  CleanerInvitation? _invitation;
  bool _isLoading = true;
  final _counterPriceController = TextEditingController();
  final _counterCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInvitation();
  }

  Future<void> _loadInvitation() async {
    try {
      final dio = DioClient.instance;
      final response = await dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.invitations}/${widget.invitationId}',
      );
      setState(() {
        _invitation = CleanerInvitation.fromJson(response.data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка загрузки: $e');
      }
    }
  }

  Future<void> _acceptInvitation() async {
    try {
      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id;

      final repository = OrderRepository();
      await repository.executeAction(
        _invitation!.orderId,
        OrderAction.acceptInvitation,
        {
          'cleanerId': currentUserId,
          'comment': _counterCommentController.text.isEmpty ? 'Приглашение принято' : _counterCommentController.text,
        },
      );
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Приглашение принято!');
        _loadInvitation();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    }
  }

  Future<void> _declineInvitation() async {
    try {
      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id;

      final repository = OrderRepository();
      await repository.executeAction(
        _invitation!.orderId,
        OrderAction.declineInvitation,
        {
          'cleanerId': currentUserId,
          'comment': _counterCommentController.text.isEmpty ? 'Приглашение отклонено' : _counterCommentController.text,
        },
      );
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Приглашение отклонено');
        _loadInvitation();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    }
  }

  Future<void> _acceptPrice() async {
    try {
      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id;

      final repository = OrderRepository();
      await repository.executeAction(
        _invitation!.orderId,
        OrderAction.acceptPrice,
        {
          'invitationId': widget.invitationId,
          'acceptorId': currentUserId,
          'comment': _counterCommentController.text.isEmpty ? 'Цена принята' : _counterCommentController.text,
        },
      );
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Цена принята!');
        _loadInvitation();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    }
  }

  Future<void> _rejectPrice() async {
    try {
      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id;

      final repository = OrderRepository();
      await repository.executeAction(
        _invitation!.orderId,
        OrderAction.rejectPrice,
        {
          'invitationId': widget.invitationId,
          'rejectorId': currentUserId,
          'comment': _counterCommentController.text.isEmpty ? 'Цена отклонена' : _counterCommentController.text,
        },
      );
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Предложение отклонено');
        _loadInvitation();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    }
  }

  Future<void> _sendCounterOffer() async {
    if (_counterPriceController.text.isEmpty) {
      CustomSnackbar.showError(context, 'Введите цену');
      return;
    }

    try {
      final authState = ref.read(authProvider);
      final currentUserId = authState.user?.id;

      final repository = OrderRepository();
      await repository.executeAction(
        _invitation!.orderId,
        OrderAction.counterOffer,
        {
          'invitationId': widget.invitationId,
          'senderId': currentUserId,
          'proposedPrice': double.parse(_counterPriceController.text),
          'message': _counterCommentController.text,
        },
      );
      if (mounted) {
        CustomSnackbar.showSuccess(context, 'Встречное предложение отправлено');
        _loadInvitation();
        _counterPriceController.clear();
        _counterCommentController.clear();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_invitation == null) {
      return const Scaffold(
        body: Center(child: Text('Приглашение не найдено')),
      );
    }

    final isExpired = _invitation!.isExpired;
    final status = _invitation!.status;
    final canClientAct = widget.userRole == 'CLIENT' && !isExpired;
    final canCleanerAct = widget.userRole == 'CLEANER' && !isExpired;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали приглашения'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            if (_invitation!.negotiations.isNotEmpty) _buildNegotiations(),
            const SizedBox(height: 24),
            if (status == 'PENDING' && canCleanerAct)
              _buildPendingActions(),
            if (status == 'COUNTER_OFFER')
              _buildCounterOfferActions(canClientAct, canCleanerAct),
            if (status == 'ACCEPTED')
              const Center(
                child: Text('✅ Приглашение принято', style: TextStyle(color: Colors.green)),
              ),
            if (status == 'DECLINED')
              const Center(
                child: Text('❌ Приглашение отклонено', style: TextStyle(color: Colors.red)),
              ),
            if (isExpired)
              const Center(
                child: Text('⏰ Приглашение истекло', style: TextStyle(color: Colors.orange)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Заказ #${_invitation!.orderId}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                StatusChip(status: _invitation!.status),
              ],
            ),
            const Divider(),
            _buildInfoRow('Услуга', _invitation!.serviceName),
            _buildInfoRow('Адрес', _invitation!.orderAddress),
            _buildInfoRow('Предложенная цена', '${_invitation!.proposedPrice} ₽'),
            if (_invitation!.clientComment != null && _invitation!.clientComment!.isNotEmpty)
              _buildInfoRow('Комментарий клиента', _invitation!.clientComment!),
            if (_invitation!.cleanerComment != null && _invitation!.cleanerComment!.isNotEmpty)
              _buildInfoRow('Комментарий клинера', _invitation!.cleanerComment!),
            _buildInfoRow('Действительно до', _formatDate(_invitation!.expiresAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildNegotiations() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История переговоров',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._invitation!.negotiations.map((neg) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        neg.senderName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          neg.senderRole == 'CLIENT' ? 'Клиент' : 'Клинер',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Предложил(а): ${neg.proposedPrice} ₽'),
                  if (neg.message != null && neg.message!.isNotEmpty)
                    Text(neg.message!),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(neg.createdAt),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingActions() {
    return Column(
      children: [
        CustomTextField(
          controller: _counterPriceController,
          label: 'Ваша цена (₽)',
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _counterCommentController,
          label: 'Комментарий',
          prefixIcon: Icons.message_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                onPressed: _sendCounterOffer,
                text: 'Отправить встречное',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _declineInvitation,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Отклонить'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterOfferActions(bool canClientAct, bool canCleanerAct) {
    final canAct = canClientAct || canCleanerAct;

    if (!canAct) {
      return const Center(
        child: Text('Ожидание ответа...', style: TextStyle(color: Colors.orange)),
      );
    }

    return Column(
      children: [
        CustomTextField(
          controller: _counterPriceController,
          label: 'Ваша цена (₽)',
          prefixIcon: Icons.attach_money,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _counterCommentController,
          label: 'Комментарий',
          prefixIcon: Icons.message_outlined,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                onPressed: _sendCounterOffer,
                text: 'Отправить встречное',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                onPressed: _acceptPrice,
                text: 'Принять цену',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _rejectPrice,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text('Отклонить предложение'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }
}