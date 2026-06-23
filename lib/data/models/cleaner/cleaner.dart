// lib/data/models/cleaner/cleaner.dart

class Cleaner {
  final int id;
  final int userId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatar;
  final String? avatarUrl;
  final double? rating;
  final int? completedOrders;
  final bool? isAvailable;
  final double? pricePerHour;
  final double? price;
  final String? bio;
  final String? description;
  final int? experienceYears;
  final List<String>? services;
  final List<Review>? reviews;
  final String? verificationStatus;
  final bool? identityVerified;
  final bool? criminalRecordVerified;
  final bool? medicalCertificateVerified;

  Cleaner({
    required this.id,
    required this.userId,
    required this.fullName,
    this.email,
    this.phone,
    this.avatar,
    this.avatarUrl,
    this.rating,
    this.completedOrders,
    this.isAvailable,
    this.pricePerHour,
    this.price,
    this.bio,
    this.description,
    this.experienceYears,
    this.services,
    this.reviews,
    this.verificationStatus,
    this.identityVerified,
    this.criminalRecordVerified,
    this.medicalCertificateVerified,
  });

  factory Cleaner.fromJson(Map<String, dynamic> json) {
    return Cleaner(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatar: json['avatar'] as String? ?? json['avatarUrl'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      completedOrders: json['completedOrders'] as int? ?? json['completed_orders'] as int?,
      isAvailable: json['isAvailable'] as bool? ?? json['is_available'] as bool?,
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble(),
      price: (json['price'] as num?)?.toDouble(),
      bio: json['bio'] as String?,
      description: json['description'] as String?,
      experienceYears: json['experienceYears'] as int? ?? json['experience_years'] as int?,
      services: (json['services'] as List?)?.map((e) => e as String).toList(),
      reviews: (json['reviews'] as List?)
          ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
      verificationStatus: json['verificationStatus'] as String?,
      identityVerified: json['identityVerified'] as bool?,
      criminalRecordVerified: json['criminalRecordVerified'] as bool?,
      medicalCertificateVerified: json['medicalCertificateVerified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'avatarUrl': avatarUrl,
      'rating': rating,
      'completedOrders': completedOrders,
      'isAvailable': isAvailable,
      'pricePerHour': pricePerHour,
      'price': price,
      'bio': bio,
      'description': description,
      'experienceYears': experienceYears,
      'services': services,
      'reviews': reviews?.map((e) => e.toJson()).toList(),
      'verificationStatus': verificationStatus,
      'identityVerified': identityVerified,
      'criminalRecordVerified': criminalRecordVerified,
      'medicalCertificateVerified': medicalCertificateVerified,
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
      id: json['id'] as int? ?? 0,
      clientId: json['clientId'] as int? ?? 0,
      clientName: json['clientName'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
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