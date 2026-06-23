import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_snackbar.dart';
import '../../../data/repositories/verification_repository.dart';
import '../../../data/repositories/file_repository.dart';
import '../../../data/models/verification/cleaner_verification.dart';

class PendingVerificationsScreen extends ConsumerStatefulWidget {
  const PendingVerificationsScreen({super.key});

  @override
  ConsumerState<PendingVerificationsScreen> createState() =>
      _PendingVerificationsScreenState();
}

class _PendingVerificationsScreenState
    extends ConsumerState<PendingVerificationsScreen> {
  final VerificationRepository _repository = VerificationRepository();
  final FileRepository _fileRepository = FileRepository();
  List<CleanerVerification> _pendingVerifications = [];
  bool _isLoading = true;
  bool _isDisposed = false;

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
        setState(() => _pendingVerifications = verifications);
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        CustomSnackbar.showError(context, 'Ошибка загрузки: $e');
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reviewVerification(
      int verificationId, String status, String comment) async {
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
      final url = await _fileRepository.getFileUrl(objectName);
      if (url.isNotEmpty) {
        _imageUrlCache[objectName] = url;
        return url;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  void _showImagePreview(String imageUrl) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Просмотр документа',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark_circle_fill,
                        color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.55,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.exclamationmark_triangle,
                            size: 48, color: AppColors.textHint),
                        SizedBox(height: 8),
                        Text('Не удалось загрузить'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.checkmark_shield_fill,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Проверка документов',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cleaner name
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EEFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: AppColors.gradient),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              verification.cleanerName
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          verification.cleanerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Документы',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (verification.identityDocumentObjectName != null &&
                      verification
                          .identityDocumentObjectName!.isNotEmpty)
                    _buildDocTile('Паспорт/удостоверение',
                        CupertinoIcons.creditcard_fill,
                        verification.identityDocumentObjectName!),
                  if (verification.criminalRecordObjectName != null &&
                      verification.criminalRecordObjectName!.isNotEmpty)
                    _buildDocTile('Справка о несудимости',
                        CupertinoIcons.doc_checkmark_fill,
                        verification.criminalRecordObjectName!),
                  if (verification.medicalCertificateObjectName != null &&
                      verification
                          .medicalCertificateObjectName!.isNotEmpty)
                    _buildDocTile('Медицинская справка',
                        CupertinoIcons.heart_circle_fill,
                        verification.medicalCertificateObjectName!),
                  if (verification.selfieWithDocumentObjectName != null &&
                      verification
                          .selfieWithDocumentObjectName!.isNotEmpty)
                    _buildDocTile('Селфи с паспортом',
                        CupertinoIcons.person_crop_circle_fill,
                        verification.selfieWithDocumentObjectName!),
                  if (verification.selfieObjectName != null &&
                      verification.selfieObjectName!.isNotEmpty)
                    _buildDocTile('Дополнительное селфи',
                        CupertinoIcons.photo_fill,
                        verification.selfieObjectName!),
                  const SizedBox(height: 16),
                  // Decision dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Решение',
                      labelStyle: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'VERIFIED', child: Text('✅ Одобрить')),
                      DropdownMenuItem(
                          value: 'REJECTED',
                          child: Text('❌ Отклонить')),
                    ],
                    onChanged: (v) {
                      setDialogState(() => selectedStatus = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  // Comment
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    style: const TextStyle(
                        fontFamily: 'Poppins', fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Комментарий',
                      hintText: 'Причина отклонения (если нужно)',
                      hintStyle: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: AppColors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Отмена',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              onPressed: selectedStatus != null
                  ? () {
                      _reviewVerification(
                        verification.id,
                        selectedStatus!,
                        commentController.text,
                      );
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedStatus == 'REJECTED'
                    ? const Color(0xFFD63031)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Подтвердить',
                  style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocTile(String title, IconData icon, String objectName) {
    final imageUrl = '${ApiConstants.baseUrl}/files/$objectName';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: const Text(
          'Нажмите для просмотра',
          style: TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
              fontFamily: 'Poppins'),
        ),
        trailing: const Icon(CupertinoIcons.eye_fill,
            color: AppColors.primary, size: 18),
        onTap: () => _showImagePreview(imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0EFF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary))
                  : _pendingVerifications.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadPendingVerifications,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(20, 16, 20, 20),
                            itemCount: _pendingVerifications.length,
                            itemBuilder: (_, index) {
                              final v = _pendingVerifications[index];
                              return _buildVerificationCard(v);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Header ───────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF39C12), Color(0xFFE17055)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x40F39C12),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Верификации',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_pendingVerifications.length} заявок ожидает',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _loadPendingVerifications,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(CupertinoIcons.refresh,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Verification card ────────────────────────────────

  Widget _buildVerificationCard(CleanerVerification v) {
    int uploadedCount = 0;
    if (v.identityDocumentObjectName?.isNotEmpty == true) uploadedCount++;
    if (v.criminalRecordObjectName?.isNotEmpty == true) uploadedCount++;
    if (v.medicalCertificateObjectName?.isNotEmpty == true) uploadedCount++;
    if (v.selfieWithDocumentObjectName?.isNotEmpty == true) uploadedCount++;
    if (v.selfieObjectName?.isNotEmpty == true) uploadedCount++;

    final initials = v.cleanerName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF39C12), Color(0xFFE17055)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          title: Text(
            v.cleanerName,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              fontFamily: 'Poppins',
              color: Color(0xFF2D3436),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Подано: ${_formatDate(v.submittedAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Документов: $uploadedCount/5',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF39C12),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Container(height: 1, color: const Color(0xFFF1F0FF)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Документы',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (v.identityDocumentObjectName?.isNotEmpty == true)
                    _buildDocTile('Паспорт/удостоверение',
                        CupertinoIcons.creditcard_fill,
                        v.identityDocumentObjectName!),
                  if (v.criminalRecordObjectName?.isNotEmpty == true)
                    _buildDocTile('Справка о несудимости',
                        CupertinoIcons.doc_checkmark_fill,
                        v.criminalRecordObjectName!),
                  if (v.medicalCertificateObjectName?.isNotEmpty == true)
                    _buildDocTile('Медицинская справка',
                        CupertinoIcons.heart_circle_fill,
                        v.medicalCertificateObjectName!),
                  if (v.selfieWithDocumentObjectName?.isNotEmpty == true)
                    _buildDocTile('Селфи с паспортом',
                        CupertinoIcons.person_crop_circle_fill,
                        v.selfieWithDocumentObjectName!),
                  if (v.selfieObjectName?.isNotEmpty == true)
                    _buildDocTile('Дополнительное селфи',
                        CupertinoIcons.photo_fill, v.selfieObjectName!),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showReviewDialog(v),
                      icon: const Icon(
                          CupertinoIcons.checkmark_shield_fill,
                          size: 18),
                      label: const Text('Проверить заявку'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF39C12),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Empty state ──────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFF00B894).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.checkmark_shield_fill,
                size: 42, color: Color(0xFF00B894)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Нет заявок на проверку',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3436),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Все верификации обработаны',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Helpers ──────────────────────────────────────────

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}