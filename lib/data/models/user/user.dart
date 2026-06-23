// lib/data/models/user/user.dart
class User {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? description;
  final String role;
  final DateTime createdAt;
  final bool isBlocked;

  // ✅ Добавляем cleanerId
  final int? cleanerId;

  // Cleaner-specific
  final double? rating;
  final int? completedOrders;
  final int? experienceYears;
  final bool? isAvailable;
  final String? verificationStatus;
  final double? totalEarnings;

  final bool? identityVerified;
  final bool? criminalRecordVerified;
  final bool? medicalCertificateVerified;

  User({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.description,
    required this.role,
    required this.createdAt,
    this.isBlocked = false,
    this.cleanerId, // ✅ Добавляем
    this.rating,
    this.completedOrders,
    this.experienceYears,
    this.isAvailable,
    this.verificationStatus,
    this.totalEarnings,
    this.identityVerified,
    this.criminalRecordVerified,
    this.medicalCertificateVerified,
  });

  bool get isCleaner => role.toUpperCase() == 'CLEANER';
  bool get isClient => role.toUpperCase() == 'CLIENT';
  bool get isVerified => verificationStatus == 'VERIFIED';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? json['userId'] as int? ?? 0,
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_object_name'] as String?,
      description: json['description'] as String?,
      role: json['role'] as String? ?? 'CLIENT',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isBlocked: json['isBlocked'] as bool? ?? false,
      // ✅ Парсим cleanerId
      cleanerId: json['cleanerId'] as int? ?? json['cleaner_id'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
      completedOrders: json['completedOrders'] as int?,
      experienceYears: json['experienceYears'] as int?,
      isAvailable: json['isAvailable'] as bool?,
      verificationStatus: json['verificationStatus'] as String?,
      totalEarnings: (json['totalEarnings'] as num?)?.toDouble(),
      identityVerified: json['identityVerified'] as bool?,
      criminalRecordVerified: json['criminalRecordVerified'] as bool?,
      medicalCertificateVerified: json['medicalCertificateVerified'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'description': description,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'isBlocked': isBlocked,
      'cleanerId': cleanerId,
      'rating': rating,
      'completedOrders': completedOrders,
      'experienceYears': experienceYears,
      'isAvailable': isAvailable,
      'verificationStatus': verificationStatus,
      'totalEarnings': totalEarnings,
      'identityVerified': identityVerified,
      'criminalRecordVerified': criminalRecordVerified,
      'medicalCertificateVerified': medicalCertificateVerified,
    };
  }
}