enum VerificationStatus {
  notSubmitted,
  pending,
  verified,
  rejected,
}

extension VerificationStatusExtension on VerificationStatus {
  String get value {
    switch (this) {
      case VerificationStatus.notSubmitted:
        return 'NOT_SUBMITTED';
      case VerificationStatus.pending:
        return 'PENDING';
      case VerificationStatus.verified:
        return 'VERIFIED';
      case VerificationStatus.rejected:
        return 'REJECTED';
    }
  }

  static VerificationStatus fromString(String value) {
    switch (value) {
      case 'NOT_SUBMITTED':
        return VerificationStatus.notSubmitted;
      case 'PENDING':
        return VerificationStatus.pending;
      case 'VERIFIED':
        return VerificationStatus.verified;
      case 'REJECTED':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.notSubmitted;
    }
  }

  String get displayName {
    switch (this) {
      case VerificationStatus.notSubmitted:
        return 'Не поданы';
      case VerificationStatus.pending:
        return 'На проверке';
      case VerificationStatus.verified:
        return 'Верифицирован';
      case VerificationStatus.rejected:
        return 'Отклонен';
    }
  }
}