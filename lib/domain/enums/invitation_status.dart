enum InvitationStatus {
  pending,
  accepted,
  declined,
  counterOffer,
  expired,
}

extension InvitationStatusExtension on InvitationStatus {
  String get value {
    switch (this) {
      case InvitationStatus.pending:
        return 'PENDING';
      case InvitationStatus.accepted:
        return 'ACCEPTED';
      case InvitationStatus.declined:
        return 'DECLINED';
      case InvitationStatus.counterOffer:
        return 'COUNTER_OFFER';
      case InvitationStatus.expired:
        return 'EXPIRED';
    }
  }

  static InvitationStatus fromString(String value) {
    switch (value) {
      case 'PENDING':
        return InvitationStatus.pending;
      case 'ACCEPTED':
        return InvitationStatus.accepted;
      case 'DECLINED':
        return InvitationStatus.declined;
      case 'COUNTER_OFFER':
        return InvitationStatus.counterOffer;
      case 'EXPIRED':
        return InvitationStatus.expired;
      default:
        return InvitationStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case InvitationStatus.pending:
        return 'Ожидает';
      case InvitationStatus.accepted:
        return 'Принято';
      case InvitationStatus.declined:
        return 'Отклонено';
      case InvitationStatus.counterOffer:
        return 'Встречное предложение';
      case InvitationStatus.expired:
        return 'Истекло';
    }
  }
}