enum OrderStatus {
  open,
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.open:
        return 'OPEN';
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.accepted:
        return 'ACCEPTED';
      case OrderStatus.inProgress:
        return 'IN_PROGRESS';
      case OrderStatus.completed:
        return 'COMPLETED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'OPEN':
        return OrderStatus.open;
      case 'PENDING':
        return OrderStatus.pending;
      case 'ACCEPTED':
        return OrderStatus.accepted;
      case 'IN_PROGRESS':
        return OrderStatus.inProgress;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.open;
    }
  }

  String get displayName {
    switch (this) {
      case OrderStatus.open:
        return 'Открыт';
      case OrderStatus.pending:
        return 'В ожидании';
      case OrderStatus.accepted:
        return 'Принят';
      case OrderStatus.inProgress:
        return 'В процессе';
      case OrderStatus.completed:
        return 'Завершен';
      case OrderStatus.cancelled:
        return 'Отменен';
    }
  }
}