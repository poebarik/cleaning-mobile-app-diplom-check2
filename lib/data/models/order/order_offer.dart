// lib/data/models/order/order_offer.dart
import '../invitation/cleaner_invitation.dart';
import 'order_response.dart';
import '../invitation/negotiation.dart';

class OrderOffer {
  final int id;
  final int? invitationId;
  final int cleanerId;
  final int userId;
  final String cleanerName;
  final String? cleanerAvatar;
  final double priceOffer;
  final String? message;
  final String status;
  final bool isVerified;
  final double rating;
  final int completedOrders;
  final String type;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int orderId; // ✅ ДОБАВЛЕНО! ID заказа

  // ✅ Поля для контрпредложений
  final bool hasCounterOffer;
  final double? counterOfferPrice;
  final String? counterOfferMessage;
  final DateTime? counterOfferCreatedAt;
  final String? counterOfferStatus; // PENDING, ACCEPTED, REJECTED
  final String? counterOfferSenderRole; // CLIENT или CLEANER
  final String? counterOfferSenderName;

  OrderOffer({
    required this.id,
    required this.cleanerId,
    required this.userId,
    required this.cleanerName,
    this.cleanerAvatar,
    required this.priceOffer,
    this.message,
    required this.status,
    this.isVerified = false,
    this.rating = 0,
    this.completedOrders = 0,
    required this.type,
    required this.createdAt,
    this.expiresAt,
    required this.orderId, // ✅ Добавлен в конструктор
    this.hasCounterOffer = false,
    this.counterOfferPrice,
    this.counterOfferMessage,
    this.counterOfferCreatedAt,
    this.counterOfferStatus,
    this.counterOfferSenderRole,
    this.counterOfferSenderName,
    this.invitationId,
  });

  factory OrderOffer.fromResponse(OrderResponse response) {
    final counterOffer = response.counterOffer;

    print('📦 OrderOffer.fromResponse:');
    print('  - response.id: ${response.id}');
    print('  - response.userId (настоящий ID пользователя): ${response.userId}');
    print('  - response.cleanerId (ID в cleaners): ${response.cleanerId}');
    print('  - cleanerName: ${response.cleanerName}');

    return OrderOffer(
      id: response.id,
      cleanerId: response.cleanerId, // 2
      userId: response.userId, // 3 (настоящий ID пользователя!)
      cleanerName: response.cleanerName,
      cleanerAvatar: response.cleanerAvatar,
      priceOffer: response.priceOffer,
      message: response.message,
      status: response.status,
      isVerified: response.isVerified,
      rating: response.rating,
      completedOrders: response.completedOrders,
      type: 'response',
      createdAt: response.createdAt ?? DateTime.now(),
      expiresAt: null,
      orderId: response.orderId,
      hasCounterOffer: counterOffer != null,
      counterOfferPrice: counterOffer?.proposedPrice,
      counterOfferMessage: counterOffer?.message,
      counterOfferCreatedAt: counterOffer?.createdAt,
      counterOfferStatus: counterOffer?.status,
      counterOfferSenderRole: counterOffer?.senderRole,
      counterOfferSenderName: counterOffer?.senderName,
      invitationId: null,
    );
  }

  factory OrderOffer.fromInvitation(CleanerInvitation invitation) {
    // ✅ Получаем последнее контрпредложение из negotiations
    final hasCounterOffer = invitation.negotiations.isNotEmpty;
    final lastNegotiation = hasCounterOffer ? invitation.negotiations.last : null;

    // Получаем сообщение из комментариев
    String? message = invitation.cleanerComment ?? invitation.clientComment;

    // Статус приглашения
    String status = invitation.status;
    if (invitation.isExpired) {
      status = 'EXPIRED';
    }

    return OrderOffer(
      id: invitation.id,
      cleanerId: invitation.cleanerId,
      userId: invitation.userId,
      cleanerName: invitation.cleanerName,
      cleanerAvatar: null,
      priceOffer: invitation.proposedPrice,
      message: message,
      status: status,
      isVerified: false,
      rating: invitation.cleanerRating ?? 0,
      completedOrders: 0,
      type: 'invitation',
      createdAt: invitation.createdAt,
      expiresAt: invitation.expiresAt,
      orderId: invitation.orderId, // ✅ Берем orderId из Invitation
      hasCounterOffer: hasCounterOffer,
      counterOfferPrice: lastNegotiation?.proposedPrice,
      counterOfferMessage: lastNegotiation?.message,
      counterOfferCreatedAt: lastNegotiation?.createdAt,
      counterOfferStatus: lastNegotiation?.status,
      counterOfferSenderRole: lastNegotiation?.senderRole,
      counterOfferSenderName: lastNegotiation?.senderName,
      invitationId: invitation.id,
    );
  }

  bool get isPending => status == 'PENDING' || status == 'PENDING_CLEANER' || status == 'PENDING_CLIENT';
  bool get isAccepted => status == 'ACCEPTED';
  bool get isDeclined => status == 'DECLINED' || status == 'REJECTED';
  bool get isExpired => status == 'EXPIRED' || (expiresAt != null && expiresAt!.isBefore(DateTime.now()));
  bool get isCounterOffer => status == 'COUNTER_OFFER' || hasCounterOffer;

  // ✅ Для контрпредложения
  bool get isCounterOfferPending => counterOfferStatus == 'PENDING';
  bool get isCounterOfferAccepted => counterOfferStatus == 'ACCEPTED';
  bool get isCounterOfferRejected => counterOfferStatus == 'REJECTED';
  bool get isCounterOfferFromCleaner => counterOfferSenderRole == 'CLEANER';
  bool get isCounterOfferFromClient => counterOfferSenderRole == 'CLIENT';
}