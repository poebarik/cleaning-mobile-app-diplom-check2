class OrderResponse {
  final int id;
  final int orderId;
  final int cleanerId;
  final String cleanerName;
  final double? cleanerRating;
  final String message;
  final double priceOffer;
  final String status;
  final DateTime? createdAt;

  OrderResponse({
    required this.id,
    required this.orderId,
    required this.cleanerId,
    required this.cleanerName,
    this.cleanerRating,
    required this.message,
    required this.priceOffer,
    required this.status,
    this.createdAt,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'] as int,
      orderId: json['orderId'] as int,
      cleanerId: json['cleanerId'] as int,
      cleanerName: json['cleanerName'] as String,
      cleanerRating: (json['cleanerRating'] as num?)?.toDouble(),
      message: json['message'] as String,
      priceOffer: (json['priceOffer'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'cleanerId': cleanerId,
      'cleanerName': cleanerName,
      'cleanerRating': cleanerRating,
      'message': message,
      'priceOffer': priceOffer,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}