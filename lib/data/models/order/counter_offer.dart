// lib/data/models/order/counter_offer.dart
class CounterOffer {
  final int id;
  final double price;
  final String? comment;
  final DateTime? createdAt;
  final String? status; // PENDING, ACCEPTED, REJECTED

  CounterOffer({
    required this.id,
    required this.price,
    this.comment,
    this.createdAt,
    this.status,
  });

  factory CounterOffer.fromJson(Map<String, dynamic> json) {
    return CounterOffer(
      id: json['id'] as int,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'price': price,
      'comment': comment,
      'createdAt': createdAt?.toIso8601String(),
      'status': status,
    };
  }
}