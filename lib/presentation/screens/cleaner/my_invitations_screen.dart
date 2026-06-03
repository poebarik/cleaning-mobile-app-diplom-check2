import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../providers/invitation_provider.dart';
import '../../../routes/route_names.dart';
import '../../../data/models/invitation/cleaner_invitation.dart';

class MyInvitationsScreen extends ConsumerStatefulWidget {
  const MyInvitationsScreen({super.key});

  @override
  ConsumerState<MyInvitationsScreen> createState() => _MyInvitationsScreenState();
}

class _MyInvitationsScreenState extends ConsumerState<MyInvitationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(invitationProvider.notifier).loadCleanerInvitations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final invitationState = ref.watch(invitationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Приглашения'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(invitationProvider.notifier).loadCleanerInvitations();
        },
        child: invitationState.isLoading
            ? const ShimmerLoading(child: SizedBox(height: 120))
            : invitationState.isCleanerInvitationsLoaded &&
            invitationState.cleanerInvitations!.isNotEmpty
            ? ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invitationState.cleanerInvitations!.length,
          itemBuilder: (context, index) {
            final invitation = invitationState.cleanerInvitations![index];
            return _buildInvitationCard(invitation);
          },
        )
            : const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mail_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Нет приглашений'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(CleanerInvitation invitation) {
    final isExpired = invitation.isExpired;
    final status = invitation.status;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to invitation details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      invitation.serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(status, isExpired),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Клиент: ${invitation.clientName}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Предложено: ${invitation.proposedPrice} ₽'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Действительно до: ${_formatDate(invitation.expiresAt)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isExpired) {
    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Истекло', style: TextStyle(fontSize: 12)),
      );
    }

    Color color;
    String text;
    switch (status) {
      case 'PENDING':
        color = Colors.orange;
        text = 'В ожидании';
        break;
      case 'ACCEPTED':
        color = Colors.green;
        text = 'Принято';
        break;
      case 'DECLINED':
        color = Colors.red;
        text = 'Отклонено';
        break;
      case 'COUNTER_OFFER':
        color = Colors.blue;
        text = 'Встречное';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color)),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}