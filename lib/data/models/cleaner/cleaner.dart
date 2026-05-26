class Cleaner {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatar;
  final double? rating;
  final int? completedOrders;
  final bool? isAvailable;
  final double? pricePerHour;
  final String? bio;
  final List<String>? services;
  final List<Review>? reviews;

  Cleaner({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatar,
    this.rating,
    this.completedOrders,
    this.isAvailable,
    this.pricePerHour,
    this.bio,
    this.services,
    this.reviews,
  });

  factory Cleaner.fromJson(Map<String, dynamic> json) {
    return Cleaner(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      avatar: json['avatar'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      completedOrders: json['completedOrders'] as int?,
      isAvailable: json['isAvailable'] as bool?,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
      services: (json['services'] as List?)?.map((e) => e as String).toList(),
      reviews: (json['reviews'] as List?)
          ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'rating': rating,
      'completedOrders': completedOrders,
      'isAvailable': isAvailable,
      'pricePerHour': pricePerHour,
      'bio': bio,
      'services': services,
      'reviews': reviews?.map((e) => e.toJson()).toList(),
    };
  }
}

class Review {
  final int id;
  final int clientId;
  final String clientName;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}