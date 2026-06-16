import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../shared/widgets/image_uploader.dart';
import '../../providers/verification_provider.dart';
import '../../../data/models/verification/cleaner_verification.dart';
import '../../../domain/enums/verification_status.dart';
import '../../../data/repositories/file_repository.dart';

class CleanerVerificationScreen extends ConsumerStatefulWidget {
  const CleanerVerificationScreen({super.key});

  @override
  ConsumerState<CleanerVerificationScreen> createState() => _CleanerVerificationScreenState();
}

class _CleanerVerificationScreenState extends ConsumerState<CleanerVerificationScreen> {
  final FileRepository _fileRepository = FileRepository();

  String? _identityDocumentObjectName;
  String? _criminalRecordObjectName;
  String? _medicalCertificateObjectName;
  String? _selfieWithDocumentObjectName;
  String? _selfieObjectName;

  bool _isSubmitting = false;

  // Контроллеры для анимации
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(verificationProvider.notifier).loadMyVerification();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitVerification() async {
    if (_identityDocumentObjectName == null) {
      CustomSnackbar.showError(context, 'Загрузите паспорт или удостоверение');
      return;
    }
    if (_selfieWithDocumentObjectName == null) {
      CustomSnackbar.showError(context, 'Загрузите селфи с паспортом');
      return;
    }

    setState(() => _isSubmitting = true);

    final request = {
      'identityDocumentObjectName': _identityDocumentObjectName,
      'criminalRecordObjectName': _criminalRecordObjectName,
      'medicalCertificateObjectName': _medicalCertificateObjectName,
      'selfieWithDocumentObjectName': _selfieWithDocumentObjectName,
      'selfieObjectName': _selfieObjectName,
    };

    await ref.read(verificationProvider.notifier).submitVerification(request);

    setState(() => _isSubmitting = false);

    final state = ref.read(verificationProvider);
    if (state.isSubmitted) {
      CustomSnackbar.showSuccess(context, 'Документы отправлены на проверку');
      ref.read(verificationProvider.notifier).loadMyVerification();
    } else if (state.error != null) {
      CustomSnackbar.showError(context, state.error!);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(verificationProvider);
    final verification = verificationState.verification;
    final isPending = verification?.status == VerificationStatus.pending;
    final isVerified = verification?.status == VerificationStatus.verified;
    final isRejected = verification?.status == VerificationStatus.rejected;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Верификация',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (!isVerified && !isPending)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showInfoDialog,
              tooltip: 'Что такое верификация?',
            ),
        ],
      ),
      body: verificationState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await ref.read(verificationProvider.notifier).loadMyVerification();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с прогрессом
              _buildHeader(isVerified, isPending, isRejected, verification),
              const SizedBox(height: 24),

              // Статус карточка
              if (isVerified || isPending || isRejected)
                _buildStatusCard(isVerified, isPending, isRejected, verification),

              if (!isPending && !isVerified) ...[
                const SizedBox(height: 8),
                _buildDocumentsSection(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],

              if (isPending) ...[
                const SizedBox(height: 24),
                _buildPendingInfoCard(),
              ],

              if (isRejected && verification != null) ...[
                const SizedBox(height: 24),
                _buildRejectedInfoCard(verification),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isVerified, bool isPending, bool isRejected, CleanerVerification? verification) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.gradient),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.verified_user, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text(
          isVerified ? 'Вы верифицированы!' : 'Пройдите верификацию',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isVerified
              ? 'Ваш аккаунт подтверждён. Клиенты доверяют вам больше.'
              : 'Подтвердите свою личность, чтобы получать больше заказов',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isVerified, bool isPending, bool isRejected, CleanerVerification? verification) {
    if (isVerified) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.success.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.success.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              'Верификация пройдена',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.success),
            ),
            const SizedBox(height: 8),
            Text(
              'Ваши документы проверены и подтверждены',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (verification != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildVerifiedBadge('Паспорт', true),
                  _buildVerifiedBadge('Справка о несудимости', verification.criminalRecordVerified),
                  _buildVerifiedBadge('Медсправка', verification.medicalCertificateVerified),
                  _buildVerifiedBadge('Селфи', verification.selfieVerified),
                ],
              ),
            ],
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildVerifiedBadge(String text, bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isVerified ? AppColors.success : Colors.grey,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.hourglass_empty,
            size: 14,
            color: isVerified ? AppColors.success : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isVerified ? AppColors.success : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Документы для верификации',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Загрузите следующие документы для подтверждения личности',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Паспорт (обязательный)
        _buildDocumentTile(
          title: 'Паспорт или удостоверение',
          subtitle: 'Главная страница с фото и пропиской',
          icon: Icons.credit_card,
          required: true,
          isUploaded: _identityDocumentObjectName != null,
          onUpload: () => _showImagePicker('identity'),
        ),

        const SizedBox(height: 16),

        // Справка о несудимости
        _buildDocumentTile(
          title: 'Справка о несудимости',
          subtitle: 'Повышает доверие клиентов',
          icon: Icons.gavel,
          required: false,
          isUploaded: _criminalRecordObjectName != null,
          onUpload: () => _showImagePicker('criminal'),
        ),

        const SizedBox(height: 16),

        // Медицинская справка
        _buildDocumentTile(
          title: 'Медицинская справка',
          subtitle: 'Справка о состоянии здоровья',
          icon: Icons.medical_services,
          required: false,
          isUploaded: _medicalCertificateObjectName != null,
          onUpload: () => _showImagePicker('medical'),
        ),

        const SizedBox(height: 16),

        // Селфи с паспортом (обязательный)
        _buildDocumentTile(
          title: 'Селфи с паспортом',
          subtitle: 'Фото с разворотом паспорта в руке',
          icon: Icons.camera_alt,
          required: true,
          isUploaded: _selfieWithDocumentObjectName != null,
          onUpload: () => _showImagePicker('selfie_with_doc'),
        ),

        const SizedBox(height: 16),

        // Дополнительное селфи
        _buildDocumentTile(
          title: 'Дополнительное селфи',
          subtitle: 'Простое фото для дополнительной проверки',
          icon: Icons.face,
          required: false,
          isUploaded: _selfieObjectName != null,
          onUpload: () => _showImagePicker('selfie'),
        ),
      ],
    );
  }

  Widget _buildDocumentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool required,
    required bool isUploaded,
    required VoidCallback onUpload,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onUpload,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isUploaded ? Icons.check : icon,
                    color: isUploaded ? AppColors.success : AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          if (required) ...[
                            const SizedBox(width: 4),
                            const Text('*', style: TextStyle(color: Colors.red)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (isUploaded) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: AppColors.success),
                              SizedBox(width: 4),
                              Text('Загружено', style: TextStyle(fontSize: 10, color: AppColors.success)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isReady = _identityDocumentObjectName != null && _selfieWithDocumentObjectName != null;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                isReady ? Icons.check_circle : Icons.info_outline,
                color: isReady ? AppColors.success : AppColors.textHint,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isReady
                      ? 'Все обязательные документы загружены'
                      : 'Загрузите паспорт и селфи с паспортом',
                  style: TextStyle(
                    fontSize: 13,
                    color: isReady ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          onPressed: isReady && !_isSubmitting ? _submitVerification : null,
          text: _isSubmitting ? 'Отправка...' : 'Отправить на проверку',
          isLoading: _isSubmitting,
        ),
      ],
    );
  }

  Widget _buildPendingInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_empty, size: 40, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          const Text(
            'Документы на проверке',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 12),
          Text(
            'Ваши документы отправлены на проверку менеджеру. Обычно это занимает 1-2 рабочих дня.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
            backgroundColor: Colors.orange.withOpacity(0.2),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedInfoCard(CleanerVerification verification) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel, size: 40, color: Colors.red),
          ),
          const SizedBox(height: 16),
          const Text(
            'Верификация отклонена',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              verification.adminComment ?? 'Причина не указана. Пожалуйста, загрузите документы заново.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.red),
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            onPressed: () {
              setState(() {
                _identityDocumentObjectName = null;
                _criminalRecordObjectName = null;
                _medicalCertificateObjectName = null;
                _selfieWithDocumentObjectName = null;
                _selfieObjectName = null;
              });
              _scrollToTop();
            },
            text: 'Подать заново',
            isOutlined: true,
          ),
        ],
      ),
    );
  }

  Future<void> _showImagePicker(String documentType) async {
    // Здесь ваш код для выбора изображения
    // Показываем модальное окно с выбором камеры или галереи
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(documentType, 'gallery');
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Сделать фото'),
              onTap: () {
                Navigator.pop(context);
                _uploadImage(documentType, 'camera');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(String documentType, String source) async {
    // Здесь реализуйте загрузку через ImagePicker и FileRepository
    CustomSnackbar.showInfo(context, 'Выберите изображение');
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Что такое верификация?'),
        content: const Text(
          'Верификация — это процесс подтверждения вашей личности. '
              'После успешной проверки документов вы получите специальный значок, '
              'который повышает доверие клиентов и увеличивает количество заказов.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}