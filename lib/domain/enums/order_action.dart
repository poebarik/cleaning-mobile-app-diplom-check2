// lib/domain/enums/order_action.dart
enum OrderAction {
  respond,
  selectCleaner,
  sendInvitation,  // ✅ ДОБАВЛЯЕМ
  acceptInvitation,
  declineInvitation,
  counterOffer,
  acceptPrice,
  rejectPrice,
  start,
  complete,
  cancel,
  assignByManager,
}

extension OrderActionExtension on OrderAction {
  String get value {
    switch (this) {
      case OrderAction.respond:
        return 'RESPOND';
      case OrderAction.selectCleaner:
        return 'SELECT_CLEANER';
      case OrderAction.sendInvitation:  // ✅ ДОБАВЛЯЕМ
        return 'SEND_INVITATION';
      case OrderAction.acceptInvitation:
        return 'ACCEPT_INVITATION';
      case OrderAction.declineInvitation:
        return 'DECLINE_INVITATION';
      case OrderAction.counterOffer:
        return 'COUNTER_OFFER';
      case OrderAction.acceptPrice:
        return 'ACCEPT_PRICE';
      case OrderAction.rejectPrice:
        return 'REJECT_PRICE';
      case OrderAction.start:
        return 'START';
      case OrderAction.complete:
        return 'COMPLETE';
      case OrderAction.cancel:
        return 'CANCEL';
      case OrderAction.assignByManager:
        return 'ASSIGN_BY_MANAGER';
    }
  }

  static OrderAction fromString(String value) {
    switch (value) {
      case 'RESPOND':
        return OrderAction.respond;
      case 'SELECT_CLEANER':
        return OrderAction.selectCleaner;
      case 'SEND_INVITATION':  // ✅ ДОБАВЛЯЕМ
        return OrderAction.sendInvitation;
      case 'ACCEPT_INVITATION':
        return OrderAction.acceptInvitation;
      case 'DECLINE_INVITATION':
        return OrderAction.declineInvitation;
      case 'COUNTER_OFFER':
        return OrderAction.counterOffer;
      case 'ACCEPT_PRICE':
        return OrderAction.acceptPrice;
      case 'REJECT_PRICE':
        return OrderAction.rejectPrice;
      case 'START':
        return OrderAction.start;
      case 'COMPLETE':
        return OrderAction.complete;
      case 'CANCEL':
        return OrderAction.cancel;
      case 'ASSIGN_BY_MANAGER':
        return OrderAction.assignByManager;
      default:
        return OrderAction.respond;
    }
  }
}