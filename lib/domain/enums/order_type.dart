enum OrderType {
  companyAssigned,
  marketplace,
  directInvitation
}

extension OrderTypeExtension on OrderType {
  String get value {
    switch (this) {
      case OrderType.companyAssigned:
        return 'COMPANY_ASSIGNED';
      case OrderType.marketplace:
        return 'MARKETPLACE';
      case OrderType.directInvitation:
        return 'DIRECT_INVITATION'; // ✅ Добавляем
    }
  }

  static OrderType fromString(String value) {
    switch (value) {
      case 'COMPANY_ASSIGNED':
        return OrderType.companyAssigned;
      case 'MARKETPLACE':
        return OrderType.marketplace;
      case 'DIRECT_INVITATION': // ✅ Добавляем
        return OrderType.directInvitation;
      default:
        return OrderType.companyAssigned;
    }
  }
}