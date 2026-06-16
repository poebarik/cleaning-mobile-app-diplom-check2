import '../../../domain/enums/verification_status.dart';

class CleanerVerification {
  final int id;
  final int cleanerId;
  final String cleanerName;
  final VerificationStatus status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? adminComment;

  // Имена документов
  final String? identityDocumentObjectName;
  final String? criminalRecordObjectName;
  final String? medicalCertificateObjectName;
  final String? selfieWithDocumentObjectName;
  final String? selfieObjectName;

  // Статусы проверки
  final bool identityVerified;
  final bool criminalRecordVerified;
  final bool medicalCertificateVerified;
  final bool selfieVerified;
  final bool verified;

  CleanerVerification({
    required this.id,
    required this.cleanerId,
    required this.cleanerName,
    required this.status,
    this.submittedAt,
    this.reviewedAt,
    this.adminComment,
    this.identityDocumentObjectName,
    this.criminalRecordObjectName,
    this.medicalCertificateObjectName,
    this.selfieWithDocumentObjectName,
    this.selfieObjectName,
    required this.identityVerified,
    required this.criminalRecordVerified,
    required this.medicalCertificateVerified,
    required this.selfieVerified,
    required this.verified,
  });

  factory CleanerVerification.fromJson(Map<String, dynamic> json) {
    return CleanerVerification(
      id: json['id'] ?? 0,
      cleanerId: json['cleanerId'] ?? 0,
      cleanerName: json['cleanerName'] ?? '',
      status: VerificationStatusExtension.fromString(json['status'] ?? 'NOT_SUBMITTED'),
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
      adminComment: json['adminComment'],
      identityDocumentObjectName: json['identityDocumentObjectName'],
      criminalRecordObjectName: json['criminalRecordObjectName'],
      medicalCertificateObjectName: json['medicalCertificateObjectName'],
      selfieWithDocumentObjectName: json['selfieWithDocumentObjectName'],
      selfieObjectName: json['selfieObjectName'],
      identityVerified: json['identityVerified'] ?? false,
      criminalRecordVerified: json['criminalRecordVerified'] ?? false,
      medicalCertificateVerified: json['medicalCertificateVerified'] ?? false,
      selfieVerified: json['selfieVerified'] ?? false,
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cleanerId': cleanerId,
      'cleanerName': cleanerName,
      'status': status.value,
      'submittedAt': submittedAt?.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'adminComment': adminComment,
      'identityDocumentObjectName': identityDocumentObjectName,
      'criminalRecordObjectName': criminalRecordObjectName,
      'medicalCertificateObjectName': medicalCertificateObjectName,
      'selfieWithDocumentObjectName': selfieWithDocumentObjectName,
      'selfieObjectName': selfieObjectName,
      'identityVerified': identityVerified,
      'criminalRecordVerified': criminalRecordVerified,
      'medicalCertificateVerified': medicalCertificateVerified,
      'selfieVerified': selfieVerified,
      'verified': verified,
    };
  }
}