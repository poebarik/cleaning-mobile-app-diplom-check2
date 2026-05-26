enum OrderType {
  companyAssigned,
  marketplace,
}

extension OrderTypeExtension on OrderType {
  String get value {
    switch (this) {
      case OrderType.companyAssigned:
        return 'COMPANY_ASSIGNED';
      case OrderType.marketplace:
        return 'MARKETPLACE';
    }
  }

  static OrderType fromString(String value) {
    switch (value) {
      case 'COMPANY_ASSIGNED':
        return OrderType.companyAssigned;
      case 'MARKETPLACE':
        return OrderType.marketplace;
      default:
        return OrderType.companyAssigned;
    }
  }
}