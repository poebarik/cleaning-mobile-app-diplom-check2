import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../data/repositories/verification_repository.dart';
import '../../../data/repositories/file_repository.dart';
import '../../../data/models/verification/cleaner_verification.dart';
import '../../../domain/enums/verification_status.dart';

class PendingVerificationsScreen extends ConsumerStatefulWidget {
  const PendingVerificationsScreen({super.key});

  @override
  ConsumerState<PendingVerificationsScreen> createState() => _PendingVerificationsScreenState();
}

class _PendingVerificationsScreenState extends ConsumerState<PendingVerificationsScreen> {
  final VerificationRepository _repository = VerificationRepository();
  final FileRepository _fileRepository = FileRepository();
  List<CleanerVerification> _pendingVerifications = [];
  bool _isLoading = true;
  bool _isDisposed = false;

  // Кэш для URL изображений
  final Map<String, String> _imageUrlCache = {};

  @override
  void initState() {
    super.initState();
    _loadPendingVerifications();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadPendingVerifications() async {
    if (_isDisposed) return;
    setState(() => _isLoading = true);
    try {
      final verifications = await _repository.getPendingVerifications();
      if (!_isDisposed) {
        print('📦 Loaded ${verifications.length} verifications');
        setState(() => _pendingVerifications = verifications);
      }
    } catch (e) {
      print('❌ Error loading verifications: $e');
      if (!_isDisposed && mounted) {
        CustomSnackbar.showError(context, 'Ошибка загрузки: $e');
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reviewVerification(int verificationId, String status, String comment) async {
    if (_isDisposed) return;
    try {
      await _repository.reviewVerification(verificationId, status, comment);
      await _loadPendingVerifications();
      if (mounted && !_isDisposed) {
        CustomSnackbar.showSuccess(context, 'Заявка обработана');
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        CustomSnackbar.showError(context, 'Ошибка: $e');
      }
    }
  }


  Future<String?> _getImageUrl(String objectName) async {
    if (_imageUrlCache.containsKey(objectName)) {
      return _imageUrlCache[objectName];
    }

    try {
      // ✅ Теперь URL формируется правильно
      final url = await _fileRepository.getFileUrl(objectName);
      print('🔗 Получен presigned URL для $objectName: ${url.substring(0, url.length > 100 ? 100 : url.length)}...');

      if (url.isNotEmpty) {
        _imageUrlCache[objectName] = url;
        return url;
      }
      return null;
    } catch (e) {
      print('❌ Error loading image URL for $objectName: $e');
      return null;
    }
  }


  void _showImagePreview(String imageUrl) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Просмотр документа', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 48),
                        SizedBox(height: 8),
                        Text('Не удалось загрузить изображение'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(CleanerVerification verification) {
    final commentController = TextEditingController();
    String? selectedStatus;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Проверка документов'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Клинер: ${verification.cleanerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('Документы:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // Паспорт
                if (verification.identityDocumentObjectName != null && verification.identityDocumentObjectName!.isNotEmpty)
                  _buildDocumentPreviewTile(
                    title: 'Паспорт/удостоверение',
                    objectName: verification.identityDocumentObjectName!,
                  ),
                // Справка о несудимости
                if (verification.criminalRecordObjectName != null && verification.criminalRecordObjectName!.isNotEmpty)
                  _buildDocumentPreviewTile(
                    title: 'Справка о несудимости',
                    objectName: verification.criminalRecordObjectName!,
                  ),
                // Медицинская справка
                if (verification.medicalCertificateObjectName != null && verification.medicalCertificateObjectName!.isNotEmpty)
                  _buildDocumentPreviewTile(
                    title: 'Медицинская справка',
                    objectName: verification.medicalCertificateObjectName!,
                  ),
                // Селфи с паспортом
                if (verification.selfieWithDocumentObjectName != null && verification.selfieWithDocumentObjectName!.isNotEmpty)
                  _buildDocumentPreviewTile(
                    title: 'Селфи с паспортом',
                    objectName: verification.selfieWithDocumentObjectName!,
                  ),
                // Дополнительное селфи
                if (verification.selfieObjectName != null && verification.selfieObjectName!.isNotEmpty)
                  _buildDocumentPreviewTile(
                    title: 'Дополнительное селфи',
                    objectName: verification.selfieObjectName!,
                  ),

                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Решение'),
                  items: const [
                    DropdownMenuItem(value: 'VERIFIED', child: Text('Одобрить')),
                    DropdownMenuItem(value: 'REJECTED', child: Text('Отклонить')),
                  ],
                  onChanged: (value) => selectedStatus = value,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    labelText: 'Комментарий',
                    hintText: 'Причина отклонения (если нужно)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedStatus != null) {
                _reviewVerification(
                  verification.id,
                  selectedStatus!,
                  commentController.text,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Подтвердить'),
          ),
        ],
      ),
    );
  }


  Widget _buildDocumentPreviewTile({
    required String title,
    required String objectName,
  }) {
    final imageUrl = '${ApiConstants.baseUrl}/files/$objectName';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.blue),
        title: Text(title),
        subtitle: const Text('Нажмите для просмотра'),
        trailing: const Icon(Icons.visibility, color: Colors.blue),
        onTap: () => _showImagePreview(imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки на верификацию'),
        actions: [
          IconButton(
            onPressed: _loadPendingVerifications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingVerifications.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Нет заявок на проверку'),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _pendingVerifications.length,
        itemBuilder: (context, index) {
          final v = _pendingVerifications[index];

          int uploadedCount = 0;
          if (v.identityDocumentObjectName != null && v.identityDocumentObjectName!.isNotEmpty) uploadedCount++;
          if (v.criminalRecordObjectName != null && v.criminalRecordObjectName!.isNotEmpty) uploadedCount++;
          if (v.medicalCertificateObjectName != null && v.medicalCertificateObjectName!.isNotEmpty) uploadedCount++;
          if (v.selfieWithDocumentObjectName != null && v.selfieWithDocumentObjectName!.isNotEmpty) uploadedCount++;
          if (v.selfieObjectName != null && v.selfieObjectName!.isNotEmpty) uploadedCount++;

          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(v.cleanerName.substring(0, 1).toUpperCase()),
              ),
              title: Text(v.cleanerName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Подано: ${_formatDate(v.submittedAt)}'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Загружено документов: $uploadedCount/5',
                      style: const TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Документы:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      if (v.identityDocumentObjectName != null && v.identityDocumentObjectName!.isNotEmpty)
                        _buildDocumentPreviewTile(
                          title: 'Паспорт/удостоверение',
                          objectName: v.identityDocumentObjectName!,
                        ),
                      if (v.criminalRecordObjectName != null && v.criminalRecordObjectName!.isNotEmpty)
                        _buildDocumentPreviewTile(
                          title: 'Справка о несудимости',
                          objectName: v.criminalRecordObjectName!,
                        ),
                      if (v.medicalCertificateObjectName != null && v.medicalCertificateObjectName!.isNotEmpty)
                        _buildDocumentPreviewTile(
                          title: 'Медицинская справка',
                          objectName: v.medicalCertificateObjectName!,
                        ),
                      if (v.selfieWithDocumentObjectName != null && v.selfieWithDocumentObjectName!.isNotEmpty)
                        _buildDocumentPreviewTile(
                          title: 'Селфи с паспортом',
                          objectName: v.selfieWithDocumentObjectName!,
                        ),
                      if (v.selfieObjectName != null && v.selfieObjectName!.isNotEmpty)
                        _buildDocumentPreviewTile(
                          title: 'Дополнительное селфи',
                          objectName: v.selfieObjectName!,
                        ),

                      const SizedBox(height: 16),
                      CustomButton(
                        onPressed: () => _showReviewDialog(v),
                        text: 'Проверить заявку',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute}';
  }
}