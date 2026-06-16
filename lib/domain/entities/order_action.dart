// lib/domain/enums/order_action.dart
enum OrderAction {
  respond,
  selectCleaner,
  sendInvitation,
  acceptInvitation,
  declineInvitation,
  counterOffer,
  acceptPrice,
  rejectPrice,
  assignByManager,
  start,
  complete,
  cancel,
}

extension OrderActionExtension on OrderAction {
  String get value {
    switch (this) {
      case OrderAction.respond:
        return 'RESPOND';
      case OrderAction.selectCleaner:
        return 'SELECT_CLEANER';
      case OrderAction.sendInvitation:
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
      case OrderAction.assignByManager:
        return 'ASSIGN_BY_MANAGER';
      case OrderAction.start:
        return 'START';
      case OrderAction.complete:
        return 'COMPLETE';
      case OrderAction.cancel:
        return 'CANCEL';
    }
  }
}